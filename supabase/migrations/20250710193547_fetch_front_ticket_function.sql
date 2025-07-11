-- -*- sql-product: postgres; -*-

create or replace function core.fetch_front_ticket(front_id text)
  returns setof core.ticket
  language sql
as $sql$
  select
  1 id,
  jsonb_build_object(
    'ticket_with_messages', jsonb_build_object(
      'subject', jsonb_agg(message)->0->>'subject',
      'messages', jsonb_agg(message))) document,
  null::vector(384) embedding
  from (
    select
      jsonb_build_object(
	'type', 'MESSAGE',
	'subject', subject,
	'direction', direction,
	'created_at', posted_at,
	'text', body) message
      from (
	select
	  jsonb_array_elements->>'id' id,
	  jsonb_array_elements->>'created_at' posted_at,
	  jsonb_array_elements->>'subject' subject,
	  case when (jsonb_array_elements->>'is_inbound')::bool then 'INCOMING' else 'OUTGOING' end direction,
	  jsonb_array_elements->>'text' body
	  from (
	    select
	      jsonb_array_elements(
		(
		  http(
		    (
		      'GET',
		      format('https://api2.frontapp.com/conversations/%s/messages', front_id),
		      array[http_header('Authorization', format('Bearer %s', (select decrypted_secret from vault.decrypted_secrets where name = 'front_api_key')))],
		      'application/json',
		      json_build_object()::text))).content::jsonb->'_results')) t
	 union
	select
	  jsonb_array_elements->>'id' id,
	  jsonb_array_elements->>'posted_at' posted_at,
	  '' subject,
	  'COMMENT' direction,
	  jsonb_array_elements->>'body' body
	  from (
	    select
	      jsonb_array_elements(
		(
		  http(
		    (
		      'GET',
		      format('https://api2.frontapp.com/conversations/%s/comments', front_id),
		      array[http_header('Authorization', format('Bearer %s', (select decrypted_secret from vault.decrypted_secrets where name = 'front_api_key')))],
		      'application/json',
		      json_build_object()::text))).content::jsonb->'_results')) t
	 order by 2) t) t;
  $sql$;
