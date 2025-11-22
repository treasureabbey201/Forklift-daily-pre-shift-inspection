# Forklift Daily Pre-Shift Inspection

Equipment safety platform documenting operator checks, identifying defects, and preventing workplace incidents.

## Overview

This smart contract system provides a blockchain-based solution for managing forklift pre-shift inspections in warehouse and industrial environments. By leveraging the Stacks blockchain and Clarity smart contracts, the platform creates an immutable audit trail of equipment safety checks, defect reporting, and maintenance tracking.

## Purpose

The Forklift Daily Pre-Shift Inspection system addresses critical workplace safety requirements by:

- **Documenting Pre-Shift Checks**: Recording comprehensive operator inspections before each shift
- **Identifying Equipment Defects**: Capturing detailed defect information including severity and location
- **Removing Unsafe Trucks**: Flagging equipment that fails inspection criteria for immediate removal from service
- **Tracking Repairs**: Managing the complete lifecycle of maintenance requests and repair completion
- **Ensuring Operator Safety**: Creating accountability and compliance with OSHA and industry safety standards

## Key Features

### Inspection Management
- Submit detailed pre-shift inspection reports with equipment ID, operator details, and timestamp
- Record multiple inspection checklist items (brakes, steering, lights, horn, etc.)
- Assign pass/fail status to each inspection
- Generate unique inspection IDs for tracking and auditing

### Defect Reporting
- Document equipment defects discovered during inspections
- Categorize defects by severity (minor, major, critical)
- Include detailed descriptions and affected components
- Link defects to specific inspection records

### Equipment Status Tracking
- Maintain real-time operational status for each forklift (operational, out-of-service, under-repair)
- Automatically flag equipment based on inspection results
- Prevent use of equipment with critical safety issues
- Track equipment history and maintenance patterns

### Repair Coordination
- Create maintenance work orders linked to defects
- Assign repair priority based on defect severity
- Track repair completion and verification
- Return equipment to operational status after repairs

### Operator Accountability
- Record operator certifications and training status
- Track individual operator inspection history
- Maintain compliance with licensing requirements
- Generate operator performance metrics

## Technical Architecture

### Smart Contracts

The platform consists of the following Clarity smart contract:

- **forklift-inspection-coordinator**: Core contract managing inspections, defects, equipment status, repairs, and operator records

### Data Structures

- **Inspections**: Equipment ID, operator, timestamp, checklist items, overall result
- **Defects**: Defect ID, equipment ID, severity, description, discovery date
- **Equipment Records**: Equipment ID, status, last inspection date, defect count
- **Repair Orders**: Order ID, equipment ID, defect ID, priority, completion status
- **Operator Records**: Operator ID, certification status, inspection count

## Use Cases

### Daily Operations
1. Operator arrives for shift and retrieves assigned forklift
2. Performs comprehensive pre-shift inspection using checklist
3. Records inspection results via contract (pass/fail for each item)
4. System generates inspection record with unique ID
5. If defects found, creates defect reports with severity ratings
6. Critical defects automatically flag equipment as out-of-service

### Maintenance Workflow
1. Defect report triggers maintenance work order creation
2. Maintenance team receives prioritized repair list
3. Repairs completed and verified
4. Equipment status updated to operational
5. Inspection and repair history permanently recorded on blockchain

### Compliance Auditing
1. Safety managers access complete inspection history
2. Filter by date range, equipment, or operator
3. Identify patterns of recurring defects
4. Generate compliance reports for regulatory agencies
5. Verify operator certification currency

## Benefits

- **Improved Safety**: Systematic equipment checks reduce workplace accidents
- **Regulatory Compliance**: Automated documentation satisfies OSHA requirements
- **Accountability**: Blockchain immutability prevents record tampering
- **Preventive Maintenance**: Defect trends enable proactive equipment servicing
- **Cost Reduction**: Early defect detection prevents costly breakdowns
- **Audit Trail**: Complete history for incident investigations and insurance claims

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Stacks wallet for contract deployment

### Installation

```bash
# Clone the repository
git clone https://github.com/treasureabbey201/Forklift-daily-pre-shift-inspection.git

# Navigate to project directory
cd Forklift-daily-pre-shift-inspection

# Install dependencies
npm install

# Run tests
clarinet test

# Check contract syntax
clarinet check
```

### Deployment

```bash
# Deploy to Stacks testnet
clarinet deploy --testnet

# Deploy to Stacks mainnet
clarinet deploy --mainnet
```

## Contract Interactions

### Submit Inspection
```clarity
(contract-call? .forklift-inspection-coordinator submit-inspection 
  equipment-id 
  operator-principal 
  inspection-items 
  overall-result)
```

### Report Defect
```clarity
(contract-call? .forklift-inspection-coordinator report-defect 
  equipment-id 
  severity 
  description 
  component)
```

### Update Equipment Status
```clarity
(contract-call? .forklift-inspection-coordinator update-equipment-status 
  equipment-id 
  new-status)
```

### Create Repair Order
```clarity
(contract-call? .forklift-inspection-coordinator create-repair-order 
  equipment-id 
  defect-id 
  priority)
```

## Safety Standards Compliance

This system supports compliance with:
- OSHA 1910.178 (Powered Industrial Trucks)
- ANSI/ITSDF B56.1 Safety Standard
- Workplace safety regulations across jurisdictions
- Insurance and liability requirements

## Future Enhancements

- Integration with IoT sensors for automated inspections
- Mobile application for field inspection submission
- Predictive maintenance using machine learning on defect patterns
- Integration with fleet management systems
- Real-time alerting for critical safety issues
- Multi-language support for global operations

## License

MIT License - See LICENSE file for details

## Support

For questions, issues, or contributions, please open an issue on GitHub or contact the development team.

## Acknowledgments

Built with Clarinet and Clarity for the Stacks blockchain ecosystem. Designed to improve workplace safety and regulatory compliance in industrial operations.
