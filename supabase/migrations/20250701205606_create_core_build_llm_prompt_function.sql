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
		array[http_header('Authorization', format('Bearer %s', (select decrypted_secret from vault.decrypted_secrets where name = 'HF_TOKEN')))],
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

-- create or replace function core.build_llm_prompt(t core.ticket, k int default 10)
--   returns text
--   language sql
--   stable as $function$
--   select
--   format(
--     $$
-- # CONTEXT

-- ## INSTRUCTIONS

-- You are a customer support engineer.  Your job is to help customers solve their issues by writing helpful, accurate, and timely responses, or internal comments to coordinate with colleagues.  First, you will be presented with a NEW SUPPORT TICKET.  Second, you will be presented with a series of PAST RESOLVED TICKETS which may offer relevant language, troubleshooting steps, or internal advice for dealing with the NEW SUPPORT TICKET.

-- Please generate the next OUTTBOUND message for the NEW SUPPORT TICKET based on experience from PAST RESOLVED TICKETS.

-- ## NEW SUPPORT TICKET
-- %s

-- ## PAST RESOLVED TICKETS
-- %s
-- $$,
-- format_ticket_for_prompt(t, k),
-- (
--   select
--     string_agg(format_ticket_for_embedding(st), E'\n---\n')
--     from
--       core.search_tickets(t, k) st
--    where
--      st.id != t.id))
--   $function$;

