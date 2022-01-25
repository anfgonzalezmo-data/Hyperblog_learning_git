set fecha_ini = '2021-01-01';
set fecha_fin = '2021-12-31';
with
base as (
  -----COBROS---  
select o.FECHA::date as mes,
'COBROS' as TIPO,
CASE when p.reference_model = 'RappiPay_CC' then 'RappiPay' else p.reference_model end as reference_model,
coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente,
--  a.card_type,t.GATEWAY_TOKEN,t.GATEWAY_TYPE,p.gateway_name,
p.amount as total
from global_payments.co_cobros_cc o 
join co_pg_ms_payment_transactions_public.purchases p on o.table_id = p.id and o.tipo in ('COBROS_A','COBROS')
left join co_pg_ms_payment_transactions_public.transactions t on p.transaction_id = t.id
left join co_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'CO'
  left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'CO'
  left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'CO'
  left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'CO'
where o.FECHA::date between $fecha_ini::date and $fecha_fin::Date
--group by 1,2,3 --,4,5,6,7

union all

  -----REFUNDS-----
  
select o.FECHA::date as mes, 
'REFUNDS' as TIPO,
CASE when r.reference_model = 'RappiPay_CC' then 'RappiPay' else r.reference_model end as reference_model,
coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente,
--  a.card_type,t.GATEWAY_TOKEN,t.GATEWAY_TYPE,p.gateway_name,
-r.amount as total
from global_payments.co_cobros_cc o 
join co_pg_ms_payment_transactions_public.refund r on o.table_id = r.id and o.tipo in ('REFUNDS_REINTEGRO','REFUNDS_GASTO')
left join co_pg_ms_payment_transactions_public.purchases p on r.purchase_id = p.id
left join co_pg_ms_payment_transactions_public.transactions t on r.transaction_id = t.id
left join co_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text and t.GATEWAY_TYPE not in ('RappiPay','bank_account')
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'CO'
  left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'CO'
  left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'CO'
  left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'CO'
where o.FECHA::date between $fecha_ini::date and $fecha_fin::Date
--group by 1,2,3 --,4,5,6,7

UNION ALL
  -----COBROS OTHERS--------------  
select p.created_at::date as mes,
'COBROS_OTHERS' as TIPO,
    CASE when p.reference_model = 'RappiPay_CC' then 'RappiPay' else p.reference_model end as reference_model, 
coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente,
--  a.card_type,t.GATEWAY_TOKEN,t.GATEWAY_TYPE,p.gateway_name,
p.amount as total
from co_pg_ms_payment_transactions_public.purchases p 
left join co_pg_ms_payment_transactions_public.transactions t on p.transaction_id = t.id
left join co_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'CO'
  left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'CO'
  left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'CO'
  left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'CO'
where p.created_at::date between  $fecha_ini::date and $fecha_fin::Date
  and p.reference_model <> 'Order'
  AND p.amount <> 0
  and p.state_id in (4,9,10)
--group by 1,2,3-- ,4,5,6,7

union all

  -----REFUNDS OTHERS----------------
  
select  r.created_at::date as mes, 
'REFUNDS_OTHERS' as TIPO,
CASE when r.reference_model = 'RappiPay_CC' then 'RappiPay' else r.reference_model end as reference_model, 
coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente,
--  a.card_type,t.GATEWAY_TOKEN,t.GATEWAY_TYPE,p.gateway_name,
-r.amount as total
from co_pg_ms_payment_transactions_public.refund r 
left join co_pg_ms_payment_transactions_public.purchases p on r.purchase_id = p.id
left join co_pg_ms_payment_transactions_public.transactions t on r.transaction_id = t.id
left join co_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'CO'
  left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'CO'
  left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'CO'
  left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'CO'
where r.created_at::date between  $fecha_ini::date and $fecha_fin::Date
    and r.reference_model <> 'Order'
  AND r.amount <> 0
  and r.state_id in (4)
--group by 1,2,3 --,4,5,6,7

  )


select MES::date as dia, adquiriente, TIPO, reference_model, SUM(TOTAL) AS TOTAL,Count(*)as NUM_ORDERS
FROM BASE
group BY 1,2,3,4
order by 1,2,3,4

