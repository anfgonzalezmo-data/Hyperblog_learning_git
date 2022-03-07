set fecha_ini='2021-12-01';
set fecha_fin='2021-12-31';
select * from (
with base as 
(
select distinct *
,row_number() over (order by mes) as index_rn
,reference_id as LLAVE_Rappi
from CO_WRITABLE.CO_ADQUIRENCIAS_DB
where adquiriente  = ('RappiCard')
and type in ('Ventas_Orders','Ventas_Others')
and mes::date between $fecha_ini::date and $fecha_fin::date
),
adquirencia as (
---------------RAPPICARD-------------------------
SELECT
*  
,round((AMOUNT/100),0) as monto
,REFERENCE_ID as LLAVE_RAPPICARD
FROM FIVETRAN.RAPPIPAY_RPP_SHARE_INFORMATION_RAPPIPAY_CO.GATEWAY_CO
where  STATE = 'SUCCESS'
and OPERATION IN ('VOID','PURCHASE')
)
select
--'Colombia' as PAIS
--,'Ventas' as Rubro
mes::date as mes
,type
,vertical
,reference_model
,adquiriente
--,card_type
--,gateway_token
,gateway_type
,gateway_name
,gateway_transaction_id
,LLAVE_Rappi
,LLAVE_RAPPICARD
,ID
,NUMAUT
,FECHA
,FEES
,COUNTRY
,OPERATION
,STATE
,VIA
,CODE
,abs(sum(monto)) as Ventas_adq_man 
,abs(sum(total)) as Ventas_Rappi_man
,abs((sum(monto) / sum(total)))as CONC_MAN_VEN
,0 as FEE_ADQ_MAN
,Ventas_adq_man*0.012 as FEE_RAPPI_MAN
,div0(FEE_ADQ_MAN,FEE_RAPPI_MAN) AS CONC_MAN_FEE
,0 as TAX_ADQ_MAN
,0 as TAX_RAPPI_MAN
,DIV0(TAX_ADQ_MAN,TAX_RAPPI_MAN) as CONC_MAN_TAX
,COUNT(distinct LLAVE_RAPPICARD) as TRX_ADQ
,COUNT(distinct LLAVE_Rappi) as TRX_RAPPI
,TRX_ADQ-TRX_RAPPI AS FALTANTES
from 
(
select * 
,row_number() over (partition by base.index_rn order by base.mes asc ) as rn  
from 
base 
left join adquirencia 
on adquirencia.REFERENCE_ID = base.reference_id 
and ABS(adquirencia.monto) = ABS(base.total)
where mes::date between $fecha_ini::date and $fecha_fin::date
)
where rn=1
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19
--order 1,2,4
)
union all

select *
from (
with base as 
(
select distinct *
,row_number() over (order by mes) as index_rn
,reference_id as LLAVE_RAPPI
from CO_WRITABLE.CO_ADQUIRENCIAS_DB
where adquiriente  = ('RappiCard')
and type in ('Refunds_Orders','Refunds_Others')
and mes::date between $fecha_ini::date and $fecha_fin::date
),
adquirencia as (
---------------RAPPICARD-------------------------
SELECT
*  
,round((AMOUNT/100),0) as monto
,REFERENCE_ID as LLAVE_RAPPICARD
FROM FIVETRAN.RAPPIPAY_RPP_SHARE_INFORMATION_RAPPIPAY_CO.GATEWAY_CO
where  STATE = 'SUCCESS'
and OPERATION IN ('VOID','REFUND')
)
select
--'Colombia' as PAIS
--,'Refunds' as Rubro
mes::date as mes
,type
,vertical
,reference_model
,adquiriente
--,card_type
--,gateway_token
,gateway_type
,gateway_name
,gateway_transaction_id
,LLAVE_Rappi
,LLAVE_RAPPICARD
,ID
,NUMAUT
,FECHA
,FEES
,COUNTRY
,OPERATION
,STATE
,VIA
,CODE
,abs(sum(monto)) as Ventas_adq_man 
,abs(sum(total)) as Ventas_Rappi_man
,abs((sum(monto) / sum(total)))as CONC_MAN_VEN
,0 as FEE_ADQ_MAN
,Ventas_adq_man*0.012 as FEE_RAPPI_MAN
,div0(FEE_ADQ_MAN,FEE_RAPPI_MAN) AS CONC_MAN_FEE
,0 as TAX_ADQ_MAN
,0 as TAX_RAPPI_MAN
,DIV0(TAX_ADQ_MAN,TAX_RAPPI_MAN) as CONC_MAN_TAX
,COUNT(distinct LLAVE_RAPPICARD) as TRX_ADQ
,COUNT(distinct LLAVE_Rappi) as TRX_RAPPI
,TRX_ADQ-TRX_RAPPI AS FALTANTES
from 
(
select * 
,row_number() over (partition by base.index_rn order by base.mes asc ) as rn  
from 
base 
left join adquirencia 
on adquirencia.REFERENCE_ID = base.reference_id 
and ABS(adquirencia.monto) = ABS(base.total)
where mes::date between $fecha_ini::date and $fecha_fin::date
)
where rn=1
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19
)
order by 1,9





