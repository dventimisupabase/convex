-- -*- sql-product: postgres; -*-

create or replace function db_pre_request()
  returns void
  language sql
  security definer
as $sql$
  select http_set_curlopt('curlopt_timeout', '60');
$sql$;
