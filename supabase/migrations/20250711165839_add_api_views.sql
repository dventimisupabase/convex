-- -*- sql-product: postgres; -*-

create or replace function comment (conversation_id text)
  returns text
  language sql
  stable
as $function$
  select core.call_together_chat((select core.build_llm_prompt(t, 5, 'COMMENT') from (select * from core.fetch_front_ticket('cnv_1hyef8ta')) t));
  $function$;

grant execute on function "comment" to authenticated;

create or replace function reply (conversation_id text)
  returns text
  language sql
  stable
as $function$
  select core.call_together_chat((select core.build_llm_prompt(t, 5, 'OUTBOUND') from (select * from core.fetch_front_ticket('cnv_1hyef8ta')) t));
  $function$;

grant execute on function "reply" to authenticated;
