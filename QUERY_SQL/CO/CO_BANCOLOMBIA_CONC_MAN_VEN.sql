set fecha_ini='2021-12-01';
set fecha_fin='2022-02-11';
with base as
(
  
select *
,row_number() over (order by mes) as index_rn
from CO_WRITABLE.CO_ADQUIRENCIAS_DB
where adquiriente = 'Bancolombia'
and type in ('Ventas_Orders','Ventas_Others')
and mes::date between $fecha_ini::date and $fecha_fin::date
  
),

acquirer as (
  
select *
from SIMETRIKDB_PUBLIC.CO__ADQUIRENCIA__BANCOLOMBIA__COPY
where TIPO_DE_TRANSACCION in ('COMPRA','COMPRAS')
and  SKT__UNIQUENESS = 1
  
)

select
'Colombia' as PAIS
,mes::date as FECHA
,ADQUIRIENTE
,type as RUBRO
,SUM(VALOR_TOTAL) as VENTAS_ADQ_MAN
,SUM(total) as VENTAS_RAPPI_MAN
,div0(VENTAS_ADQ_MAN,VENTAS_RAPPI_MAN) as CONC_MAN_VEN
,SUM(VALOR_COMISION) AS FEE_ADQ_MAN
,0 as FEE_RAPPI_MAN
,div0(FEE_ADQ_MAN,FEE_RAPPI_MAN) AS CONC_MAN_FEE
,SUM(VALOR_IVA+VALOR_IMPOCONSUMO+VALOR_RETE_FUENTE+VALOR_RETE_FUENTE+VALOR_RETE_IVA+VALOR_RETE_ICA) as TAX_ADQ_MAN
,FEE_RAPPI_MAN*0.19 AS TAX_RAPPI_MAN
,DIV0(TAX_ADQ_MAN,TAX_RAPPI_MAN) as CONC_MAN_TAX
,SUM(VALOR_NETO) as PAYOUT_ADQ_MAN
,0 as PAYOUT_RAPPI_MAN
,COUNT(distinct SKT_ID) as TRX_ADQ
,COUNT(distinct gateway_transaction_id) as TRX_RAPPI
,TRX_ADQ-TRX_RAPPI AS FALTANTES
from
(
  
select *
,row_number() over (partition by base.index_rn order by base.mes asc ) as rn
from base 
left join 
acquirer
on acquirer.ID_TRX = base.gateway_transaction_id 
and acquirer.VALOR_TOTAL = base.total
and left(acquirer.TARJETA,4) = left(base.first_six_digits,4)
and right(acquirer.TARJETA,4) =base.last_four_digits
  
)
where rn=1
group by 1,2,3,4
order by 1,2,3,4