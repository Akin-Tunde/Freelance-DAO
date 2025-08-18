// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
contract Invoicing is Ownable {
    enum InvoiceStatus { Pending, Approved, Rejected }
    struct Invoice { uint id; string description; uint amount; InvoiceStatus status; }
    mapping(uint => Invoice) public invoices; uint public invoiceCounter; address public freelancer;
    event InvoiceCreated(uint indexed id, string description, uint amount); event InvoiceStatusChanged(uint indexed id, InvoiceStatus status);
    constructor(address _projectContract, address _freelancer) Ownable(_projectContract) { freelancer = _freelancer; }
    function createInvoice(string memory _desc, uint _amount) external {
        require(msg.sender == freelancer, "Invoicing: Not the project freelancer");
        invoiceCounter++; invoices[invoiceCounter] = Invoice(invoiceCounter, _desc, _amount, InvoiceStatus.Pending);
        emit InvoiceCreated(invoiceCounter, _desc, _amount);
    }
    function approveInvoice(uint _invoiceId) external onlyOwner { Invoice storage invoice = invoices[_invoiceId]; require(invoice.status == InvoiceStatus.Pending, "Invoicing: Invoice not pending"); invoice.status = InvoiceStatus.Approved; emit InvoiceStatusChanged(_invoiceId, InvoiceStatus.Approved); }
    function rejectInvoice(uint _invoiceId) external onlyOwner { Invoice storage invoice = invoices[_invoiceId]; require(invoice.status == InvoiceStatus.Pending, "Invoicing: Invoice not pending"); invoice.status = InvoiceStatus.Rejected; emit InvoiceStatusChanged(_invoiceId, InvoiceStatus.Rejected); }
}