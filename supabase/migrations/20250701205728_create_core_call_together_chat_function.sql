-- -*- sql-product: postgres; -*-

select core.call_together_chat('What is the capital of France?');

create or replace function core.call_together_chat(
  prompt text,
  model text default 'deepseek-ai/DeepSeek-V3'
)
  returns text
  language sql
  stable
as $function$
  select
  (
    http(
      (
	'POST',
	'https://api.together.xyz/v1/chat/completions',
	array[http_header('Authorization', format('Bearer %s', (select decrypted_secret from vault.decrypted_secrets where name = 'together_api_key')))],
	'application/json',
	jsonb_build_object(
	  'model', model,
	  'messages', jsonb_build_array(
	    jsonb_build_object(
	      'role', 'user',
	      'content', prompt)),
	      'stream', false)::text))).content::jsonb->'choices'->0->'message'->>'content';
  $function$;
