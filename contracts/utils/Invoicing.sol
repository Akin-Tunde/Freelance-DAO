// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

// The "owner" would be the Project contract.
contract Invoicing is Ownable {
    enum InvoiceStatus { Pending, Approved, Rejected }
    
    struct Invoice {
        uint id;
        string description;
        uint amount;
        InvoiceStatus status;
    }

    mapping(uint => Invoice) public invoices;
    uint public invoiceCounter;
    
    event InvoiceCreated(uint indexed id, string description, uint amount);
    event InvoiceStatusChanged(uint indexed id, InvoiceStatus status);

    constructor(address _projectContract) Ownable(_projectContract) {}

    /**
     * @notice Creates a new invoice for a project milestone.
     * @dev Should be callable only by the freelancer of the project. This would require
     *      passing the freelancer's address to the constructor and adding a modifier.
     * @param _desc A description of the work completed for the invoice.
     * @param _amount The amount requested for this milestone.
     */
    function createInvoice(string memory _desc, uint _amount) external {
        // NOTE: Access control for the freelancer is needed here.
        invoiceCounter++;
        invoices[invoiceCounter] = Invoice(invoiceCounter, _desc, _amount, InvoiceStatus.Pending);
        emit InvoiceCreated(invoiceCounter, _desc, _amount);
    }

    /**
     * @notice Approves a pending invoice.
     * @dev Can only be called by the owner (the Project contract).
     */
    function approveInvoice(uint _invoiceId) external onlyOwner {
        Invoice storage invoice = invoices[_invoiceId];
        require(invoice.status == InvoiceStatus.Pending, "Invoicing: Invoice not pending");
        invoice.status = InvoiceStatus.Approved;
        // In a real system, this would trigger a partial payment from the Escrow contract.
        emit InvoiceStatusChanged(_invoiceId, InvoiceStatus.Approved);
    }

    function rejectInvoice(uint _invoiceId) external onlyOwner {
        Invoice storage invoice = invoices[_invoiceId];
        require(invoice.status == InvoiceStatus.Pending, "Invoicing: Invoice not pending");
        invoice.status = InvoiceStatus.Rejected;
        emit InvoiceStatusChanged(_invoiceId, InvoiceStatus.Rejected);
    }
}