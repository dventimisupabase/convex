-- -*- sql-product: postgres; -*-

create or replace function core.generate_embedding(t core.ticket_with_messages)
  returns vector(384)
  language sql
  set search_path = 'core', 'public'
as $function$
  http(
    'POST',
    'https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L12-v2/pipeline/feature-extraction',
  $function$;
