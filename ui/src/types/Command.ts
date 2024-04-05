enum Command {
  AddInvoice = "add-invoice",
  CloseChannel = "close-channel",
  CreateFunding = "create-funding",
  OpenChannel = "open-channel",
  SendPayment = "send-payment",
  SetProvider = "set-provider",
  SetUrl = "set-url",
  InvoiceAndPay = "invoice-and-pay",  // "pseudo-command"
}

export default Command;
