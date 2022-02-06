set fecha_ini='2021-01-01';
set fecha_fin='2021-12-31';

-----------------CONCILIACION WOMPI---------------

with base as (
 select distinct *
 ,row_number() over (order by mes) as index_rn
from  (
---------------------COBROS------------------------
select o.FECHA::date as mes, 'Ventas_Orders' as type,p.reference_model,
 coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente,
  p.reference_id, left(p.first_six_digits,4) AS BIN, p.last_four_digits, p.gateway_name,t.gateway_transaction_id,
       case
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'paymentez' then coalesce(t.gateway_specific_response_fields:paymentez:authorization_code, replace(p.raw_response:transaction:gateway_specific_response_fields:paymentez:authorization_code, '"')::text)
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'cyber_source' then coalesce(replace(au.raw_response:transaction:gateway_specific_response_fields:cyber_source:authorization_code, '"')::string, replace(p.raw_response:transaction:gateway_specific_response_fields:cyber_source:authorization_code, '"')::string)
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'worldpay' then coalesce(t.authorization_code, replace(p.raw_response:transaction:gateway_specific_response_fields:worldpay:authorisation_id, '"')::string) 
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'global_collect' then replace(p.raw_response:transaction:gateway_specific_response_fields:global_collect:authorisation_code, '"')::text
           else t.authorization_code
       end as auth_code,
  t.id as transaction_id, p.id as purchase_id,
  case WHEN (p.amount<=40000) then (p.amount*0.015) else 600 end AS COSTO_FEE_TRANS_rappi,
  p.amount as total
from global_payments.co_cobros_cc o 
join co_pg_ms_payment_transactions_public.purchases p on o.table_id = p.id and o.tipo in ('COBROS_A','COBROS')
left join co_pg_ms_payment_transactions_public.transactions t on p.transaction_id = t.id
left join co_pg_ms_payment_transactions_public.authorizations au on au.id= p.authorization_id                                      
left join co_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'CO'
left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'CO'
left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'CO'
left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'CO'
where o.FECHA::date between $fecha_ini::date and $fecha_fin::date
  
 UNION ALL
  
---------------------COBROS OTHERS------------------------
select p.created_at::date as mes,  'Ventas_Others' as type, p.reference_model,
  coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente,
  p.reference_id, left(p.first_six_digits,4) AS BIN, p.last_four_digits, p.gateway_name,t.gateway_transaction_id,
    case
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'paymentez' then coalesce(t.gateway_specific_response_fields:paymentez:authorization_code, replace(p.raw_response:transaction:gateway_specific_response_fields:paymentez:authorization_code, '"')::text)
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'cyber_source' then coalesce(replace(au.raw_response:transaction:gateway_specific_response_fields:cyber_source:authorization_code, '"')::string, replace(p.raw_response:transaction:gateway_specific_response_fields:cyber_source:authorization_code, '"')::string)
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'worldpay' then coalesce(t.authorization_code, replace(p.raw_response:transaction:gateway_specific_response_fields:worldpay:authorisation_id, '"')::string) 
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'global_collect' then replace(p.raw_response:transaction:gateway_specific_response_fields:global_collect:authorisation_code, '"')::text
           else t.authorization_code
       end as auth_code,                                                                                
  t.id as transaction_id, p.id as purchase_id,
  case WHEN (p.amount<=40000) then (p.amount*0.015) else 600 end AS COSTO_FEE_TRANS_rappi,
  p.amount as total
from co_pg_ms_payment_transactions_public.purchases p 
left join co_pg_ms_payment_transactions_public.transactions t on p.transaction_id = t.id
left join co_pg_ms_payment_transactions_public.authorizations au on au.id= p.authorization_id                                          
left join co_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'CO'
left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'CO'
left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'CO'
left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'CO'
where p.created_at::date between $fecha_ini::date and $fecha_fin::date
  and p.reference_model <> 'Order'
  AND p.amount <> 0
  and p.state_id in (4,9,10)
  
UNION ALL 
  
---------------------REFUNDS------------------------
select o.FECHA::date as mes, 'Refunds_Orders' as type,p.reference_model,
 coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente, 
  p.reference_id, left(p.first_six_digits,4) AS BIN, p.last_four_digits, r.gateway_name,t.gateway_transaction_id,
    case
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'paymentez' then coalesce(t.gateway_specific_response_fields:paymentez:authorization_code, replace(p.raw_response:transaction:gateway_specific_response_fields:paymentez:authorization_code, '"')::text)
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'cyber_source' then coalesce(replace(au.raw_response:transaction:gateway_specific_response_fields:cyber_source:authorization_code, '"')::string, replace(p.raw_response:transaction:gateway_specific_response_fields:cyber_source:authorization_code, '"')::string)
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'worldpay' then coalesce(t.authorization_code, replace(p.raw_response:transaction:gateway_specific_response_fields:worldpay:authorisation_id, '"')::string) 
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'global_collect' then replace(p.raw_response:transaction:gateway_specific_response_fields:global_collect:authorisation_code, '"')::text
           else t.authorization_code
       end as auth_code,                                                                                
  t.id as transaction_id, p.id as purchase_id,
  case WHEN (-r.amount<=40000) then (-r.amount*0.015) else 600 end AS COSTO_FEE_TRANS_rappi,
-r.amount as total
from global_payments.co_cobros_cc o 
join co_pg_ms_payment_transactions_public.refund r on o.table_id = r.id and o.tipo in ('REFUNDS_REINTEGRO','REFUNDS_GASTO')
left join co_pg_ms_payment_transactions_public.purchases p on r.purchase_id = p.id
left join co_pg_ms_payment_transactions_public.transactions t on r.transaction_id = t.id
left join co_pg_ms_payment_transactions_public.authorizations au on au.id= p.authorization_id                                          
left join co_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text and t.GATEWAY_TYPE not in ('RappiPay','bank_account')
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'CO'
left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'CO'
left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'CO'
left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'CO'
where o.FECHA::date between $fecha_ini::date and $fecha_fin::date
  
UNION ALL
  
---------------------REFUNDS OTHERS------------------------
 select r.created_at::date as mes, 'Refunds_Others' as type,p.reference_model,
  coalesce(c1.acquirer, coalesce(c2.acquirer, coalesce(c3.acquirer, coalesce (c4.acquirer, 'SIN IDENTIFICAR')))) AS adquiriente, 
  p.reference_id, left(p.first_six_digits,4) AS BIN, p.last_four_digits, r.gateway_name,t.gateway_transaction_id,
    case
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'paymentez' then coalesce(t.gateway_specific_response_fields:paymentez:authorization_code, replace(p.raw_response:transaction:gateway_specific_response_fields:paymentez:authorization_code, '"')::text)
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'cyber_source' then coalesce(replace(au.raw_response:transaction:gateway_specific_response_fields:cyber_source:authorization_code, '"')::string, replace(p.raw_response:transaction:gateway_specific_response_fields:cyber_source:authorization_code, '"')::string)
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'worldpay' then coalesce(t.authorization_code, replace(p.raw_response:transaction:gateway_specific_response_fields:worldpay:authorisation_id, '"')::string) 
           when split_part(p.raw_response:transaction:gateway_type,'"',1) = 'global_collect' then replace(p.raw_response:transaction:gateway_specific_response_fields:global_collect:authorisation_code, '"')::text
           else t.authorization_code
       end as auth_code,                                                                                
  t.id as transaction_id, p.id as purchase_id,
  case WHEN (-r.amount<=40000) then (-r.amount*0.015) else 600 end AS COSTO_FEE_TRANS_rappi,
-r.amount as total
from co_pg_ms_payment_transactions_public.refund r 
left join co_pg_ms_payment_transactions_public.purchases p on r.purchase_id = p.id
left join co_pg_ms_payment_transactions_public.transactions t on r.transaction_id = t.id
left join co_pg_ms_payment_transactions_public.authorizations au on au.id= p.authorization_id                                          
left join co_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'CO'
left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'CO'
left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'CO'
left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'CO'
where r.created_at::date between $fecha_ini::date and $fecha_fin::date
  and r.reference_model <> 'Order'
  AND r.amount <> 0
  and r.state_id in (4,9,10)
) as co_adquirencia
where adquiriente  = ('Wompi')
and type in ('Ventas_Orders','Ventas_Others')
),
wompi as (

select *
,case WHEN (ADQ_AMOUNT<=40000) then (ADQ_AMOUNT*0.015) else 600 end AS fee_calculado_Wompi
from SIMETRIKDB_PUBLIC.REPORT__CO__ADQUIRENCIA__DIRECTA__2
where Rappi_adquiriente ='Wompi'

)

select 
'Colombia' as PAIS
,mes::date as FECHA
,ADQUIRIENTE
,'Ventas' as RUBRO
,SUM(ADQ_AMOUNT) as VENTAS_ADQ_SIM
,SUM(total) as VENTAS_RAPPI_SIM
,div0(VENTAS_ADQ_SIM,VENTAS_RAPPI_SIM) as CONC_SIM_VEN
,SUM(fee_calculado_Wompi) AS FEE_ADQ_SIM
,sum(fee_calculado_Wompi) as FEE_RAPPI_SIM
,div0(FEE_ADQ_SIM,FEE_RAPPI_SIM) AS CONC_SIM_FEE
,SUM(ADQ_IVA_AMOUNT+ADQ_RETEIVA_AMOUNT+ADQ_RETEICA_AMOUNT+ADQ_RETEFUENTE_AMOUNT) as TAX_ADQ_SIM
,FEE_RAPPI_SIM*0.19 AS TAX_RAPPI_SIM
,DIV0(TAX_ADQ_SIM,TAX_RAPPI_SIM) as CONC_SIM_TAX
,COUNT(distinct ADQ_SKT_ID) as TRX_ADQ_SIM
,COUNT(distinct gateway_transaction_id) as TRX_RAPPI_SIM
,TRX_ADQ_SIM-TRX_RAPPI_SIM AS FALTANTES_SIM
from
(
select *
,row_number() over (partition by base.index_rn order by base.mes asc ) as rn
from base 
left join wompi  
on wompi.rappi_transaction_id = base.transaction_id 
and wompi.adq_amount = base.total
where 1=1 and 1=1 
)
where rn=1
group by 1,2,3
order by 1,2
