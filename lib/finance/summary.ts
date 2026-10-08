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
