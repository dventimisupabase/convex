-- -*- sql-product: postgres; -*-

create or replace function core.search_tickets(t core.ticket_with_messages, k integer default 5)
  returns setof core.ticket_with_messages
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
      t
      from core.ticket_with_messages t, output q
     where t.embedding is not null
     order by t.embedding <=> q.embedding
     limit 5)
  select * from results;
  $function$;
