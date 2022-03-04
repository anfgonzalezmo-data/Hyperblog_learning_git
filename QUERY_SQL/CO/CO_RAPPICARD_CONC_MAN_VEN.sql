set fecha_ini='2021-12-01';
set fecha_fin='2021-12-31';
with base as 
(
select distinct *
,row_number() over (order by mes) as index_rn
  ,reference_id as LLAVE_Rappi
from CO_WRITABLE.co_adquirencia_2
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
'Colombia' as PAIS
,mes::date as mes
,adquiriente
,LLAVE_Rappi
,LLAVE_RAPPICARD
,type
,OPERATION
,'Ventas' as Rubro
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
group by 1,2,3,4,5,6,7,8
order by 1,2,4


