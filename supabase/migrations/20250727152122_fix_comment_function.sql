-- -*- sql-product: postgres -*-

CREATE OR REPLACE FUNCTION public.comment(conversation_id text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  select core.call_together_chat((select core.build_llm_prompt(t, 5, 'COMMENT') from (select * from core.fetch_front_ticket(conversation_id)) t));
  $function$
