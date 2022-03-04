set hora_verano_ini='2021-03-28';
set hora_verano_fin='2021-10-31';
set fecha_ini='2020-12-30';
set fecha_fin='2022-01-02';

with base as (
 select *
,row_number() over(order by mes) as index_rn
from (
  -----COBROS---  
select 
o.FECHA::date as mes
,'Ventas_orders' as tipo
,p.reference_model
,coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente
,case when od.vertical = 'RAPPI TRAVEL' then 'Travel' else 'Core' end as vertical
,a.card_type
,t.GATEWAY_TOKEN
,t.GATEWAY_TYPE
,p.gateway_name
,t.gateway_transaction_id
,p.reference_id
,p.amount as total
from global_payments.br_cobros_cc o 
left join global_finances.br_order_details od on o.order_id = od.order_id
join br_pg_ms_payment_transactions_public.purchases p on o.table_id = p.id and o.tipo in ('COBROS_A','COBROS')
left join br_pg_ms_payment_transactions_public.transactions t on p.transaction_id = t.id
left join bR_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'BR'
left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'BR'
left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'BR'
left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'BR'
where o.FECHA::date between  $fecha_ini::date and $fecha_fin::Date
--group by 1,2,3,4 --,5,6,7,8
union all
  
select 
p.created_at::date as mes
,'Ventas_others' as tipo
,CASE when p.reference_model = 'RappiPay_CC' then 'RappiPay' else p.reference_model end as reference_model
,coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente
,case when od.vertical = 'RAPPI TRAVEL' then 'Travel' else 'Core' end as vertical
,a.card_type
,t.GATEWAY_TOKEN
,t.GATEWAY_TYPE
,p.gateway_name
,t.gateway_transaction_id
,p.reference_id
,p.amount as total
from br_pg_ms_payment_transactions_public.purchases p 
left join global_finances.br_order_details od on p.reference_id = od.order_id
left join br_pg_ms_payment_transactions_public.transactions t on p.transaction_id = t.id
left join bR_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'BR'
  left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'BR'
  left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'BR'
      left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'BR'
where p.created_at::date between $fecha_ini::date and $fecha_fin::Date
  and p.reference_model <> 'Order'
  AND p.amount <> 0
  and p.state_id in (4,9)
--group by 1,2,3-- ,4,5,6,7  
  
UNION ALL
  
  -----REFUNDS-----
select 
o.FECHA::date as mes
,'Refunds_orders' as tipo
,r.reference_model
,coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente
,case when od.vertical = 'RAPPI TRAVEL' then 'Travel' else 'Core' end as vertical
,a.card_type
,t.GATEWAY_TOKEN
,t.GATEWAY_TYPE
,p.gateway_name
,t.gateway_transaction_id
,r.reference_id
,-r.amount as total
from global_payments.br_cobros_cc o 
  left join global_finances.br_order_details od on o.order_id = od.order_id
join br_pg_ms_payment_transactions_public.refund r on o.table_id = r.id and o.tipo in ('REFUNDS_REINTEGRO','REFUNDS_GASTO')
left join br_pg_ms_payment_transactions_public.purchases p on r.purchase_id = p.id
left join br_pg_ms_payment_transactions_public.transactions t on p.transaction_id = t.id
left join bR_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'BR'
left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'BR'
left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'BR'
left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'BR'
where o.FECHA::date between   $fecha_ini::date and $fecha_fin::Date
  
UNION ALL
 
select 
r.created_at::date as mes
,'Refunds_others' as tipo
,CASE when r.reference_model = 'RappiPay_CC' then 'RappiPay' else r.reference_model end as reference_model
, coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente
,case when od.vertical = 'RAPPI TRAVEL' then 'Travel' else 'Core' end as vertical
,a.card_type
,t.GATEWAY_TOKEN
,t.GATEWAY_TYPE
,p.gateway_name
,t.gateway_transaction_id
,r.reference_id
,-r.amount as total
from br_pg_ms_payment_transactions_public.refund r
left join global_finances.br_order_details od on r.reference_id = od.order_id
left join br_pg_ms_payment_transactions_public.purchases p on r.purchase_id = p.id
left join br_pg_ms_payment_transactions_public.transactions t on p.transaction_id = t.id
left join bR_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'BR'
left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'BR'
left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'BR'
left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'BR'
where r.created_at::date between  $fecha_ini::date and $fecha_fin::Date
  and r.reference_model <> 'Order'
  AND r.amount <> 0
  and r.state_id in (4)
--group by 1,2,3 --,4,5,6,7
) where adquiriente in ('Adyen','Adyen_Travel','Adyen_pay')
  ),
  
adyen as (

select *
,case when charindex('_', merchant_reference) != 0 then substring(merchant_reference, 1, charindex('_', merchant_reference) - 1)   
else merchant_reference end as adyen_reference
,(CASE WHEN BOOKING_DATE::datetime between $hora_verano_ini::datetime and $hora_verano_fin::datetime then dateadd(hour,5,BOOKING_DATE::datetime) 
  else dateadd(hour,4,BOOKING_date::datetime) end ) 
  as ADYEN_TIME
--,row_number() over (order by SKT_ID) as index_rn
from simetrikdb_public.Global__Payments__Accounting__Reports 
where record_type in ('SentForSettle' ,'SentForRefund')
and merchant_account in ('RappiBR','RappiBR_Loyalty','RappiBR_market','RappiBR_Pay','RappiBR_Safe'
                         ,'RappiBR_GooglePay','RappiDonations_BR','RappiBR_Travel','RappiBank_BR','RappiBR_Validations')
and skt__uniqueness = 1
--and booking_date::date between $fecha_ini::date and $fecha_fin::date
  
)

select
--* index_rn
mes
,ADYEN_TIME::date as ADYEN_TIME
,tipo
,gateway_token
--,reference_id
,adquiriente
,merchant_account
,reference_model
,SUM(captured_pc) as Adq_Ventas
,SUM (total) as Rappi_Ventas
,Adq_ventas/Rappi_Ventas as  conciliacion
,COUNT(adyen_reference) as adq_trx
,COUNT(reference_id) as rappi_trx
from (
SELECT 
*
,row_number() over (partition by base.index_rn order by base.mes asc ) as rn
from base
left join adyen 
on cast(base.reference_id as varchar) = adyen.adyen_reference 
and total = captured_pc
and mes::date=booking_date::date
--and index_base = 1
)
where rn=1
group by 1,2,3,4,5,6,7--,8,9
order by 1,2,3,4,5
