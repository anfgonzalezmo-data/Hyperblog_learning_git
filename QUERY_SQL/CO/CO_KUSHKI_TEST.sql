set fecha_ini='2021-12-11';
set fecha_fin='2021-12-31';
--NO_CACHE;
with base as (
 select * 
 ,row_number() over (order by mes) as index_rn
from(
  -----COBROS---  
select o.FECHA::date as mes
  ,'Ventas_Orders' as type
  ,coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente
  ,p.reference_id
  ,left(p.first_six_digits,6) AS BIN
  ,p.last_four_digits
  ,t.authorization_code
  ,t.id as transaction_id
  ,t.gateway_transaction_id
  ,CASE when p.reference_model = 'RappiPay_CC' then 'RappiPay' else p.reference_model end as reference_model
  ,p.amount as total_rappi
from global_payments.co_cobros_cc o 
join co_pg_ms_payment_transactions_public.purchases p on o.table_id = p.id and o.tipo in ('COBROS_A','COBROS')
left join co_pg_ms_payment_transactions_public.transactions t on p.transaction_id = t.id
left join co_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'CO'
  left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'CO'
  left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'CO'
 left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'CO'
where o.FECHA::date between $fecha_ini::date and $fecha_fin::date
  
 UNION ALL
  
select 
  p.created_at::date as mes
  ,'Ventas_Others' as type
  ,coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente
  ,p.reference_id
  , left(p.first_six_digits,6) AS BIN
  , p.last_four_digits
  , t.authorization_code
  , t.id as transaction_id
  ,t.gateway_transaction_id
  ,CASE when p.reference_model = 'RappiPay_CC' then 'RappiPay' else p.reference_model end as reference_model
  ,p.amount as total_rappi
from co_pg_ms_payment_transactions_public.purchases p 
left join co_pg_ms_payment_transactions_public.transactions t on p.transaction_id = t.id
left join co_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'CO'
  left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'CO'
  left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'CO'
 left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'CO'
where p.created_at::date between $fecha_ini::date and $fecha_fin::date
  and p.reference_model <> 'Order'
  AND p.amount <> 0
  and p.state_id in (4,9)

  UNION ALL
  
select 
  o.FECHA::date as mes
  ,'Refunds_Orders' as type
  ,coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente
  ,r.reference_id
  ,left(r.first_six_digits,6) AS BIN
  ,r.last_four_digits
  ,t.authorization_code
  ,t.id as transaction_id
  ,t.gateway_transaction_id
   ,CASE when r.reference_model = 'RappiPay_CC' then 'RappiPay' else r.reference_model end as reference_model
  ,-r.amount as total_rappi
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

UNION ALL

select
  r.created_at::date as mes
  ,'Refunds_Orders' as type
  ,coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente
  ,r.reference_id
  ,left(r.first_six_digits,6) AS BIN
  ,r.last_four_digits
  ,t.authorization_code
  ,t.id as transaction_id
  ,t.gateway_transaction_id
  ,CASE when r.reference_model = 'RappiPay_CC' then 'RappiPay' else r.reference_model end as reference_model
  ,-r.amount as total_rappi
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
and r.amount <> 0
and r.state_id in (4)

)
  where adquiriente = ('Kushki')
and type in ('Ventas_Orders','Ventas_Others')
and reference_model not in ('RappiPayCreditCard')
),
kushki as (
select *
from SIMETRIKDB_PUBLIC.co__sales__kushki
where SKT__UNIQUENESS = 1
and TRANSACTION_STATUS = 'APPROVAL'
)
select 
'Kushki' as adquiriente,
mes::date as mes,
sum(APPROVED_TRANSACTION_AMOUNT) as Ventas_adq_man, 
sum(total_rappi) as Ventas_Rappi_man,
(sum(APPROVED_TRANSACTION_AMOUNT) / sum(total_rappi)) as conciliacion
,SUM(fee_calculado) as fee_adq_man_calculado
,SUM(Tax) as Tax_adq_man_calculado
,COUNT(APPROVAL_CODE) as adq_trx
,COUNT(gateway_transaction_id) as rappi_trx
,0 as abono
from
(
select *
,(CASE 
when SKT__CREATED::date <='2021-07-31'::date then 800
when SKT__CREATED::date between '2021-08-01'::date and '2021-09-30'::date then 750
when SKT__CREATED::date between '2021-10-01'::date and '2021-12-31'::date then 650
when SKT__CREATED::date between '2022-01-01'::date and '2022-01-31'::date then 600
when SKT__CREATED::date between '2022-02-01'::date and '2022-03-31'::date then 550
when SKT__CREATED::date >'2022-04-01' then 500
else 0 
end
) as fee_calculado
,(CASE 
when SKT__CREATED::date <='2021-07-31'::date then (800*0.19)
when SKT__CREATED::date between '2021-08-01'::date and '2021-09-30'::date then (750*0.19)
when SKT__CREATED::date between '2021-10-01'::date and '2021-12-31'::date then (650*0.19)
when SKT__CREATED::date between '2022-01-01'::date and '2022-01-31'::date then (600*0.19)
when SKT__CREATED::date between '2022-02-01'::date and '2022-03-31'::date then (550*0.19)
when SKT__CREATED::date >'2022-04-01' then (500*0.19)
else 0 
end
) as Tax
,row_number() over (partition by base.index_rn order by base.mes asc) as rn
from base 
left join kushki 
on kushki.APPROVAL_CODE = base.gateway_transaction_id 
and kushki.APPROVED_TRANSACTION_AMOUNT = base.total_rappi
)
where rn =1
group by 1,2
order by 1,2
