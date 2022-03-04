set fecha_ini='2021-12-01';
set fecha_fin='2021-12-31';
with base as 
(
select distinct *
,reference_id as LLAVE_Rappi
from CO_WRITABLE.co_adquirencia_2
where adquiriente  = ('RappiCard')
and type in ('Refunds_Orders','Refunds_Others')
--and mes::date between $fecha_ini::date and $fecha_fin::date
),
adquirencia as (
---------------RAPPICARD-------------------------
SELECT
*  
,round((AMOUNT/100),0) as monto
,REFERENCE_ID as LLAVE_RAPPICARD
,row_number() over (order by FECHA,HORA) as index_rn
FROM FIVETRAN.RAPPIPAY_RPP_SHARE_INFORMATION_RAPPIPAY_CO.GATEWAY_CO
where  STATE = 'SUCCESS'
and OPERATION IN ('VOID','REFUND')
and FECHA::date between $fecha_ini::date and $fecha_fin::date
)
select
'Colombia' as PAIS
,FECHA::date as FECHA
,adquiriente
,LLAVE_Rappi
,LLAVE_RAPPICARD
,type
,OPERATION
,'Refunds' as Rubro
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
,row_number() over (partition by adquirencia.index_rn order by adquirencia.FECHA asc ) as rn  
from 
adquirencia 
left join base 
on adquirencia.REFERENCE_ID = base.reference_id 
and ABS(adquirencia.monto) = ABS(base.total)
where FECHA::date between $fecha_ini::date and $fecha_fin::date
)
where rn=1
group by 1,2,3,4,5,6,7,8
order by 1,2,4