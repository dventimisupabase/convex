-- -*- sql-product: postgres; -*-

create schema if not exists core;

create table core.ticket (
  id bigint primary key generated always as identity,
  document jsonb,
  embedding vector(384)
);

create or replace function core.normalize_message_text(text)
  returns text
  language sql
  immutable
  returns null on null input
as $$
  select regexp_replace(
    regexp_replace(
      regexp_replace(
        $1,
        E'\t', ' ', 'g'),
        E'\n{3,}', E'\n\n', 'g'),
        E'[ \t]+$', '', 'gm')
$$;

create or replace function core.format_ticket_for_embedding(t core.ticket)
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
$template$,
    t.document->'ticket_with_messages'->>'subject',
    t.document->'ticket_with_messages'->>'content'));
  $function$;

create or replace function core.embed_missing_tickets()
  returns void
  language sql
  volatile
as $$
  with
  settings as (
    select 100000 as char_budget),
  inputs as (
    select
      row_number() over () as ordinal,
      id,
      cumulative_length,
      formatted
      from
	settings,
	(
	  select
	    f.id,
	    sum(length(formatted)) over (order by f.id rows between unbounded preceding and current row) as cumulative_length,
	    formatted
	    from
	      core.ticket t,
	      lateral core.format_ticket_for_embedding(t) as f
	   where t.embedding is null) t
     where cumulative_length < settings.char_budget),
  outputs as (
    select
      ordinal,
      embedding::text::vector(384) embedding
      from
	jsonb_array_elements(
	  (
	    http(
	      (
		'POST',
		'https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L12-v2/pipeline/feature-extraction',
		array[http_header('Authorization', format('Bearer %s', (select decrypted_secret from vault.decrypted_secrets where name = 'hf_token')))],
		'application/json',
		json_build_object('inputs', (select array_agg(formatted) from inputs))::text))).content::jsonb) with ordinality as elem(embedding, ordinal))
  update
  core.ticket
  set embedding = outputs.embedding
  from
  outputs join inputs using (ordinal)
  where inputs.id = ticket.id;
$$;
