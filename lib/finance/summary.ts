export type FinanceInvoice = {
  id: string; currency: string; total_amount: number | string; status: string;
};
export type FinancePayment = {
  invoice_id: string; currency: string; amount: number | string; status: string;
};

export function calculateFinanceSummary(
  invoices: FinanceInvoice[], payments: FinancePayment[], currency: string,
) {
  const issued = invoices.filter(x => x.currency === currency &&
    ["issued", "partially_paid", "paid"].includes(x.status));
  const confirmed = payments.filter(x => x.currency === currency && x.status === "confirmed");
  const paidByInvoice = new Map<string, number>();
  for (const payment of confirmed) {
    paidByInvoice.set(payment.invoice_id,
      (paidByInvoice.get(payment.invoice_id) || 0) + Number(payment.amount));
  }
  return {
    billed: issued.reduce((n, x) => n + Number(x.total_amount), 0),
    collected: confirmed.reduce((n, x) => n + Number(x.amount), 0),
    pending: issued.reduce((n, x) => n + Math.max(0,
      Number(x.total_amount) - (paidByInvoice.get(x.id) || 0)), 0),
  };
}

export type FinanceSale = {
  id: string; currency: string; gross_amount: number | string;
};
export type CommercialFinanceInvoice = FinanceInvoice & { sale_id: string | null };

export function calculateCommercialFinanceSummary(
  sales: FinanceSale[], invoices: CommercialFinanceInvoice[],
  payments: FinancePayment[], currency: string,
) {
  const billedBySale = new Map<string, number>();
  for (const invoice of invoices) {
    if (invoice.currency !== currency || !invoice.sale_id ||
        !["issued", "partially_paid", "paid"].includes(invoice.status)) continue;
    billedBySale.set(invoice.sale_id,
      (billedBySale.get(invoice.sale_id) || 0) + Number(invoice.total_amount));
  }
  const selected = sales.filter(sale => sale.currency === currency);
  return {
    ...calculateFinanceSummary(invoices, payments, currency),
    sold: selected.reduce((total, sale) => total + Number(sale.gross_amount), 0),
    pendingBilling: selected.reduce((total, sale) => total + Math.max(0,
      Number(sale.gross_amount) - (billedBySale.get(sale.id) || 0)), 0),
  };
}
