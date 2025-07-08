-- -*- sql-product: postgres; -*-

create or replace function core.search_tickets(t core.ticket, k integer default 10)
  returns setof core.ticket
  language sql
as $function$
  with
  output as (
    select
      ordinal,
      embedding::text::vector(384)
      from
	jsonb_array_elements(
	  (
	    http(
	      (
		'POST',
		'https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L12-v2/pipeline/feature-extraction',
		array[http_header('Authorization', format('Bearer %s', (select decrypted_secret from vault.decrypted_secrets where name = 'hf_token')))],
		'application/json',
		json_build_object('inputs', (select array_agg(formatted) from (select (core.format_ticket_for_embedding(t)).formatted) t))::text))).content::jsonb) with ordinality as elem(embedding, ordinal)),
  results as (
    select
      s
      from core.ticket s, output q
     order by s.embedding <=> q.embedding
     limit k)
  select * from results;
  $function$;

create or replace function core.build_llm_prompt(t core.ticket, k int default 10, message_type core.message_type default 'OUTBOUND')
  returns text
  language sql
  stable as $function$
  select
  format(
    $$
# CONTEXT

## INSTRUCTIONS

You are a customer support engineer.  Your job is to help customers solve their issues by writing helpful, accurate, and timely responses, or internal comments to coordinate with colleagues.  First, you will be presented with a NEW SUPPORT TICKET.  Second, you will be presented with a series of PAST RESOLVED TICKETS which may offer relevant language, troubleshooting steps, or internal advice for dealing with the NEW SUPPORT TICKET.

Please generate the next %s message for the NEW SUPPORT TICKET based on experience from PAST RESOLVED TICKETS.  Those PAST RESOLVED TICKETS have a TICKET MESSAGE HISTORY recording messages between customers and customer support engineers, and between customer support engineers and each other.  Messages from the customer to a customer support engineer are denoted with INBOUND.  Messages from a customer support engineer to the customer are denoted with OUTBOUND.  Private messages between customer support engineers are denoted with COMMENT.  This document and all of the related content is organized in Markdown format, and each TICKET in the series of PAST RESOLVED TICKETS is on its own separate Markdown document.  Omit any signature block from the generated message.

## NEW SUPPORT TICKET
%s

## PAST RESOLVED TICKETS

---
%s
$$,
message_type,
(core.format_ticket_for_prompt(t)).formatted,
(
  select
    string_agg((select formatted from core.format_ticket_for_prompt(st)), E'\n---\n')
    from
      core.search_tickets(t, k) st
   where
     st.id != t.id))
  $function$;
