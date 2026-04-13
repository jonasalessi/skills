```yaml
---
name: oop-solid-coding-guide
description: Guides the creation of robust Object-Oriented Programming (OOP) code applying SOLID principles, encapsulation, and object consistency. Use when the user asks to write OOP code, refactor existing classes, apply SOLID principles, or improve system design.
---
```

# Object-Oriented Programming and SOLID Guidelines

This skill provides step-by-step guidance for writing, refactoring, and reviewing Object-Oriented (OO) code based on core design principles. Apply the following rules to ensure high cohesion, low coupling, robust encapsulation, and consistent object states.

## Step 1: Cohesion and the Single Responsibility Principle (SRP)
A cohesive class handles a single concept or responsibility. Avoid massive classes that grow indefinitely as new rules are added. Instead, extract varying behaviors into separate classes implementing a common interface.

**Bad Use Case:**
A class filled with conditionals to handle different business rules.
```java
class SalaryCalculator {
    public double calculate(Employee employee) {
        if ("DEVELOPER".equals(employee.getRole())) {
            return tenOrTwentyPercent(employee);
        }
        if ("DBA".equals(employee.getRole())) {
            return fifteenOrTwentyFivePercent(employee);
        }
        throw new RuntimeException("Invalid employee");
    }
}
```

**Good Use Case:**
Isolate each rule into its own cohesive class using an interface.
```java
public interface CalculationRule {
    double calculate(Employee f);
}

public class DeveloperRule implements CalculationRule {
    public double calculate(Employee employee) {
        if(employee.getBaseSalary() > 3000.0) return employee.getBaseSalary() * 0.8;
        return employee.getBaseSalary() * 0.9;
    }
}
// The calculation logic is now delegated, and the calculator class remains clean.
```

## Step 2: Coupling and the Dependency Inversion Principle (DIP)
Coupling occurs when classes depend on others. To minimize fragility, depend on stable abstractions (interfaces) rather than unstable concrete implementations. 

**Bad Use Case:**
A class hardcoding its dependencies, making it fragile and hard to reuse.
```java
public class InvoiceGenerator {
    private EmailSender email;
    private InvoiceDao dao;

    public InvoiceGenerator() {
        this.email = new EmailSender();
        this.dao = new InvoiceDao();
    }

    public Invoice generate(Bill bill) {
        Invoice inv = new Invoice(bill.getAmount());
        email.sendEmail(inv);
        dao.persist(inv);
        return inv;
    }
}
```

**Good Use Case:**
Depend on an interface and inject implementations.
```java
interface ActionAfterInvoiceGeneration {
    void execute(Invoice inv);
}

public class InvoiceGenerator {
    private List<ActionAfterInvoiceGeneration> actions;

    public InvoiceGenerator(List<ActionAfterInvoiceGeneration> actions) {
        this.actions = actions;
    }

    public Invoice generate(Bill bill) {
        Invoice inv = new Invoice(bill.getAmount());
        for(ActionAfterInvoiceGeneration action : actions) {
            action.execute(inv);
        }
        return inv;
    }
}
```

## Step 3: Open Classes and the Open/Closed Principle (OCP)
Classes should be open for extension but closed for modification. Instead of altering existing code when rules change, pass different implementations (abstractions) into the class.

**Bad Use Case:**
Instantiating concrete rules inside the class, forcing the class to change whenever rules change.
```java
public class PriceCalculator {
    public double calculate(Product product) {
        StandardPricingTable table = new StandardPricingTable(); // Hardcoded dependency
        DeliveryService delivery = new DeliveryService();
        
        double discount = table.discountFor(product.getValue());
        double freight = delivery.forCity(product.getCity());
        return product.getValue() * (1 - discount) + freight;
    }
}
```

**Good Use Case:**
Receiving dependencies via the constructor, allowing new behaviors to be injected without changing the class code.
```java
public class PriceCalculator {
    private PricingTable table;
    private DeliveryService delivery;

    public PriceCalculator(PricingTable table, DeliveryService delivery) {
        this.table = table;
        this.delivery = delivery;
    }

    public double calculate(Product product) {
        double discount = table.discountFor(product.getValue());
        double freight = delivery.forCity(product.getCity());
        return product.getValue() * (1 - discount) + freight;
    }
}
```

## Step 4: Encapsulation and Change Propagation
Hide implementation details to prevent changes from rippling across the system. Follow the "Tell, Don't Ask" principle: command objects to perform actions rather than asking for their state to make decisions outside of them.

**Bad Use Case:**
An external processor managing the state of an entity.
```java
public class TicketProcessor {
    public void process(List<Ticket> tickets, Invoice invoice) {
        double total = 0;
        for(Ticket t : tickets) {
            invoice.getPayments().add(new Payment(t.getAmount()));
            total += t.getAmount();
        }
        if(total >= invoice.getAmount()) {
            invoice.setPaid(true); // Encapsulation broken
        }
    }
}
```

**Good Use Case:**
The entity guards its own internal rules and state.
```java
public class Invoice {
    private List<Payment> payments;
    private double amount;
    private boolean paid;

    public void addPayment(Payment payment) {
        this.payments.add(payment);
        if(totalPayments() >= this.amount) {
            this.paid = true;
        }
    }
}
```

## Step 5: Inheritance vs. Composition and the Liskov Substitution Principle (LSP)
When using inheritance, child classes must honor the contracts (pre/post-conditions) of the parent class. If inheritance breaks contracts, favor composition over inheritance.

**Bad Use Case:**
A subclass throwing an exception for a method that the parent class supports seamlessly.
```java
public class CommonAccount {
    protected double balance;
    public void yield() {
        this.balance *= 1.1;
    }
}

public class StudentAccount extends CommonAccount {
    public void yield() {
        throw new RuntimeException("Student accounts do not yield interest"); // Breaks LSP
    }
}
```

**Good Use Case:**
Using composition to share logic without establishing a flawed inheritance tree.
```java
class BalanceManipulator {
    private double balance;
    public void yield(double rate) { this.balance *= rate; }
}

class CommonAccount {
    private BalanceManipulator manipulator = new BalanceManipulator();
    public void yield() { manipulator.yield(1.1); }
}

class StudentAccount {
    private BalanceManipulator manipulator = new BalanceManipulator();
    // Simply does not expose the yield() method, respecting its own behavior
}
```

## Step 6: Lean Interfaces and the Interface Segregation Principle (ISP)
Interfaces must be cohesive. Do not force classes to implement methods they do not need. Split "fat" interfaces into smaller, more specific ones.

**Bad Use Case:**
A single interface handling distinct responsibilities.
```java
interface Tax {
    double calculate(double fullValue);
    Invoice generateInvoice();
}

class SpecialTax implements Tax {
    public double calculate(double fullValue) { return fullValue * 0.2; }
    public Invoice generateInvoice() {
        throw new RuntimeException("This tax does not generate invoices"); // Forces bad implementation
    }
}
```

**Good Use Case:**
Segregating the responsibilities into lean interfaces.
```java
interface TaxCalculator {
    double calculate(double fullValue);
}

interface InvoiceGenerator {
    Invoice generateInvoice();
}

class SpecialTax implements TaxCalculator {
    public double calculate(double fullValue) { return fullValue * 0.2; }
}
```

## Step 7: Consistency, Tiny Types, and Rich Constructors
Objects must never exist in an invalid state. Use rich constructors to require essential data upon instantiation.

**Bad Use Case:**
Empty constructor allowing an object to be instantiated without required dependencies.
```java
class Order {
    private Client client;
    
    public Order() {} // Allows Order without a Client
    
    public void setClient(Client client) {
        this.client = client;
    }
}
```

**Good Use Case:**
Using a rich constructor to guarantee consistency from creation.
```java
class Order {
    private Client client;
    private List<Item> items;

    public Order(Client client) {
        if(client == null) throw new IllegalArgumentException("Client is required");
        this.client = client;
        this.items = new ArrayList<>();
    }
}
```

## Step 8: Design Smells (e.g., Feature Envy)
Be vigilant against "Code Smells." A common smell is "Feature Envy," where a method is more interested in the data of another object than its own.

**Bad Use Case:**
A manager class pulling data from an entity to apply business rules.
```java
class Manager {
    public void process(Invoice inv) {
        double tax = inv.calculateTax();
        if(inv.getItemCount() > 2) {
            tax *= 1.1; // Manager is calculating rules for Invoice
        }
        inv.setTaxValue(tax);
    }
}
```

**Good Use Case:**
Moving the logic directly into the entity that owns the data.
```java
class Invoice {
    private double taxValue;
    private int itemCount;

    public void processTaxes() {
        double tax = calculateTax();
        if(this.itemCount > 2) {
            tax *= 1.1;
        }
        this.taxValue = tax;
    }
}
```