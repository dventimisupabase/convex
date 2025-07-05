-- -*- sql-product: postgres; -*-

create or replace function core.format_ticket_for_prompt(t core.ticket)
  returns table(id bigint, formatted text)
  language sql
  set search_path = 'core', 'public'
as $function$
  select
  t.id,
  core.normalize_message_text(
    format(
$template$
## TICKET SUBJECT
%s
    
## TICKET DESCRIPTION
%s

## TICKET MESSAGE HISTORY
%s
$template$,
    t.document->'ticket_with_messages'->>'subject',
    t.document->'ticket_with_messages'->>'content',
    (
      select
	string_agg(item, E'\n')
	from (
	  select
	    format(
$template$
### %s
%s
$template$,
message->>'direction',
message->>'text'
	    ) item
	    from (
	      select
		jsonb_array_elements(t.document->'ticket_with_messages'->'messages') message) t) t)));
  $function$;
