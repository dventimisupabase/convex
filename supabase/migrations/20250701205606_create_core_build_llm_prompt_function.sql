-- -*- sql-product: postgres; -*-

create or replace function build_llm_prompt(t core.ticket_with_messages, k int default 10)
  returns text
  language sql
  stable as $function$
  select
  format(
    $$
# CONTEXT

## INSTRUCTIONS

You are a customer support engineer.  Your job is to help customers solve their issues by writing helpful, accurate, and timely responses, or internal comments to coordinate with colleagues.  First, you will be presented with a NEW SUPPORT TICKET.  Second, you will be presented with a series of PAST RESOLVED TICKETS which may offer relevant language, troubleshooting steps, or internal advice for dealing with the NEW SUPPORT TICKET.

Please generate the next OUTTBOUND message for the NEW SUPPORT TICKET based on experience from PAST RESOLVED TICKETS.

## NEW SUPPORT TICKET
%s

## PAST RESOLVED TICKETS
%s
$$,
format_ticket_with_messages(t, k),
(
  select
    string_agg(format_ticket_with_messages(st), E'\n---\n')
    from
      core.search_tickets(
	t.document->'ticket_with_messages'->>'subject',
	t.document->'ticket_with_messages'->>'content',
	t.document->'ticket_with_messages'->'messages'->0->>'text') st
   where
     st.id != t.id))
  $function$;

