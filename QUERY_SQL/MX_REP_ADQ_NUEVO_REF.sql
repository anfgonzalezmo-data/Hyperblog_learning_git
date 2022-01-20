select *
from global_payments.MX_cobros_cc o 
left join global_finances.mx_order_details od on o.order_id = od.order_id
join mx_pglr_ms_payment_transaction_public.refund r on o.table_id = r.id and o.tipo in ('REFUNDS_REINTEGRO','REFUNDS_GASTO')
left join mx_pglr_ms_payment_transaction_public.purchases p on r.purchase_id = p.id
left join mx_pglr_ms_payment_transaction_public.transactions t on r.transaction_id = t.id
left join mx_PG_MS_USER_ASSET_ACCOUNT_PUBLIC.ACCOUNTS_OFUSCATED a on a.id::text = p.payment_method_token::text 
left join  rappi_payments_staging.comercios_rappi c1 on c1.type = 'Tradicional' and a.card_type = c1.card_type and t.GATEWAY_TOKEN = c1.GATEWAY_TOKEN and c1.country = 'MX'
left join  rappi_payments_staging.comercios_rappi c2 on c2.type = 'Sin Tarjeta' and a.card_type is null and t.GATEWAY_TOKEN = c2.GATEWAY_TOKEN and c2.country = 'MX'
left join  rappi_payments_staging.comercios_rappi c3 on c3.type = 'Por Gateway' and a.card_type is null and t.GATEWAY_TYPE = c3.GATEWAY_TOKEN and c3.country = 'MX'
left join rappi_payments_staging.comercios_rappi c4 on c4.type = 'Gateway-Tarjeta' and a.card_type = c4.card_type and t.GATEWAY_TYPE = c4.GATEWAY_TOKEN and c4.country = 'MX'