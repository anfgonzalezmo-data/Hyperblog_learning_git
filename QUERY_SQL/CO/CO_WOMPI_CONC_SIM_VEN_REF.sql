set fecha_ini='2021-12-01';
set fecha_fin='2022-02-11';
with base as
(
  
select *
,row_number() over (order by mes) as index_rn
,case WHEN (total<=40000) then (total*0.015) else 600 end AS COSTO_FEE_TRANS_rappi
from CO_WRITABLE.CO_ADQUIRENCIAS_DB
where adquiriente = 'Wompi'
--and type in ('Ventas_Orders','Ventas_Others')
and mes::date between $fecha_ini::date and $fecha_fin::date
  
),

acquirer as (
  
select 
 *
,case WHEN (ADQ_AMOUNT<=40000) then (ADQ_AMOUNT*0.015) else 600 end AS fee_Wompi
from SIMETRIKDB_PUBLIC.REPORT__CO__ADQUIRENCIA__DIRECTA__2
where RAPPI_ADQUIRIENTE ilike '%Wompi%'
  
)

select
'Colombia' as PAIS
,mes::date as FECHA
,ADQUIRIENTE
,type as RUBRO
,SUM(ADQ_AMOUNT) as VENTAS_ADQ_SIM
,SUM(total) as VENTAS_RAPPI_SIM
,div0(VENTAS_ADQ_SIM,VENTAS_RAPPI_SIM) as CONC_SIM_VEN
,SUM(fee_Wompi) AS FEE_ADQ_SIM
,sum(COSTO_FEE_TRANS_rappi) as FEE_RAPPI_SIM
,div0(FEE_ADQ_SIM,FEE_RAPPI_SIM) AS CONC_SIM_FEE
,SUM(ADQ_IVA_AMOUNT+ADQ_RETEIVA_AMOUNT+ADQ_RETEICA_AMOUNT+ADQ_RETEFUENTE_AMOUNT) as TAX_ADQ_SIM
,FEE_RAPPI_SIM*0.19 AS TAX_RAPPI_SIM
,DIV0(TAX_ADQ_SIM,TAX_RAPPI_SIM) as CONC_SIM_TAX
,COUNT(distinct ADQ_SKT_ID) as TRX_ADQ
,COUNT(distinct gateway_transaction_id) as TRX_RAPPI
,TRX_ADQ-TRX_RAPPI AS FALTANTES
from
(
  
select *
,row_number() over (partition by base.index_rn order by base.mes asc ) as rn
from base 
left join 
acquirer
on base.transaction_id = acquirer.rappi_transaction_id
and base.total = acquirer.adq_amount 
where mes between $fecha_ini::date and $fecha_fin::date
  
)
where rn=1
group by 1,2,3,4
order by 1,2,3,4