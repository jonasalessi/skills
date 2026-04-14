---
name: oo-solid-guide
description: Guide for applying OO and SOLID principles when writing, reviewing, or refactoring code. Use this skill when is creating classes, designing interfaces, refactoring existing code, performing code reviews, discussing architecture, designing domain models, or working with inheritance/composition — even if they don't explicitly mention 'OO' or 'SOLID'
metadata:
  author: Jonas Alessi
  reference: Orientação a Objetos e SOLID para Ninjas by Mauricio Aniche
---

# OO & SOLID Design Guide

A practical guide for writing clean, maintainable Object-Oriented code. Based on the principles from *"Orientação a Objetos e SOLID para Ninjas"*.

## The Puzzle Metaphor

Think of an OO system as a puzzle. Each class is a piece:

- **The shape** of the piece = its public interface (how it connects to others)
- **The internal drawing** = its implementation (the logic inside)

If you change the drawing but keep the shape, the rest of the puzzle is unaffected. But if you change the shape, every neighboring piece must be reshaped too. Effective OO design means **keeping shapes stable** and hiding the drawings. Every principle below serves this goal.

---

## Pillar 1: Cohesion & Single Responsibility (SRP)

A cohesive class manages **one concept** and has **one reason to change**. When a class takes on multiple responsibilities, it grows indefinitely, becomes hard to test, and can't be reused.

### How to spot low cohesion

- A class has a long chain of `if`/`when` branches selecting between unrelated behaviors
- You find yourself modifying the same file for completely unrelated business reasons (Divergent Changes smell)
- A method manipulates the internals of another object more than its own (Feature Envy smell)
- A private method extracts a responsibility that could be reused elsewhere — private methods improve readability but don't fix cohesion

### What to do

**Isolate each behavior variant into its own class behind a shared abstraction.** The parent caller should coordinate, not compute.

**When to introduce an interface**: Extract an interface only when there are (or will be) **multiple implementations** of the same behavior. Creating an interface for a single concrete class adds unnecessary indirection and clutters the codebase with 1:1 interface-to-class pairs. The exception is **hexagonal architecture** — there, port interfaces at architectural boundaries (e.g., a `InvoiceRepository` port with a single `PostgresInvoiceRepository` adapter) are justified because they decouple the domain from infrastructure, even with one implementation.

```kotlin
// ❌ Non-cohesive: one class, many unrelated rules
class SalaryCalculator {
    fun calculate(employee: Employee): Double {
        return when (employee.role) {
            Role.DEVELOPER -> tenOrTwentyPercent(employee)
            Role.DBA, Role.TESTER -> fifteenOrTwentyFivePercent(employee)
            else -> throw RuntimeException("Invalid employee")
        }
    }
}

// ✅ Cohesive: each rule is its own class
interface CalculationRule {
    fun calculate(employee: Employee): Double
}

class TenOrTwentyPercent : CalculationRule {
    override fun calculate(employee: Employee): Double =
        if (employee.baseSalary > 3000.0) employee.baseSalary * 0.8
        else employee.baseSalary * 0.9
}
```

The role enum can hold a reference to its matching rule, keeping the selection logic out of client code.

### Fat controllers are a cohesion problem

Controllers that mix business logic with infrastructure (DB access, email, web services) violate SRP. A controller should be a **coordinator** — it delegates to specialized classes and chooses which view to return. Nothing more.

```kotlin
// ❌ Fat controller: business logic + infrastructure interleaved
@PostMapping("/invoice/new")
fun createInvoice(invoice: Invoice) {
    if (invoice.isValid()) {
        if (invoice.isFromSaoPaulo()) invoice.doubleTaxes()
        if (invoice.exceedsLimit()) {
            val smtp = SMTP()
            // ... send email inline
        }
        val sql = "INSERT INTO invoices ..."
        // ... raw JDBC inline
    }
}

// ✅ Controller handles HTTP only, validate simple data input to respect the next layer, delegates to a Use Case
@PostMapping("/invoice/new")
fun createInvoice(invoice: Invoice): View {
    if (!invoice.isValid()) return view("validation-error")

    createInvoiceUseCase.execute(invoice)

    return view("success")
}

// The Use Case coordinates domain logic + infrastructure
class CreateInvoiceUseCase(
    private val businessRules: InvoiceBusinessRules,
    private val invoiceDao: InvoiceDao,
    private val erpService: ErpService
) {
    fun execute(invoice: Invoice) {
        businessRules.apply(invoice)    // domain logic
        invoiceDao.save(invoice)        // persistence
        erpService.send(invoice)        // integration
    }
}
```

The controller only cares about HTTP (validation, view selection). The **Use Case** orchestrates the application flow — business rules, persistence, integrations. This aligns with Clean / Hexagonal Architecture: domain classes stay separate from adapters (infrastructure), and the use case defines the application's behavior.

---

## Pillar 2: Coupling & Dependency Inversion (DIP)

Coupling is unavoidable — classes must interact. The goal is to couple to **stable** things (abstractions, interfaces) rather than **unstable** things (concrete implementations that change often).

### The Dependency Inversion Principle

> High-level modules should not depend on low-level modules. Both should depend on abstractions.

When a class directly depends on concrete implementations (email sender, DAO, external service), any change in those dependencies forces changes in the main class.

```kotlin
// ❌ Coupled to concrete classes
class InvoiceGenerator(
    private val emailSender: EmailSender,  // concrete
    private val dao: InvoiceDao            // concrete
) {
    fun generate(billing: Billing): Invoice {
        val invoice = Invoice(billing.monthlyValue, calculateTax(billing.monthlyValue))
        emailSender.send(invoice)
        dao.persist(invoice)
        return invoice
    }
}

// ✅ Coupled to a stable abstraction (Observer pattern)
interface PostGenerationAction {
    fun execute(invoice: Invoice)
}

class InvoiceGenerator(
    private val actions: List<PostGenerationAction>
) {
    fun generate(billing: Billing): Invoice {
        val invoice = Invoice(billing.monthlyValue, calculateTax(billing.monthlyValue))
        actions.forEach { it.execute(invoice) }
        return invoice
    }
}
```

Now adding a new post-generation behavior (SAP integration, SMS notification) requires zero changes to `InvoiceGenerator` — just implement the interface and plug it in.

### Stability heuristic

Ask: *"Is this dependency likely to change?"* Interfaces and abstract contracts are stable because they carry no implementation. Concrete classes with business logic, infrastructure code, or external integrations are unstable. Depend on the former, never the latter.

### Logical coupling warning

Watch for coupling that isn't structurally visible — e.g., changing a controller method requires remembering to update a specific view template. Make these relationships explicit through naming conventions or co-location.

---

## Pillar 3: Open-Closed Principle (OCP) & Polymorphism

> Classes should be **open for extension** but **closed for modification**.

When new behaviors are added via `if`/`when` branches inside existing classes, you're modifying code. When new behaviors are added by creating new classes that implement an abstraction, you're extending code.

### The `if` chain is a design smell

Every time you see a growing `when`/`if` block that selects between rule variants, it's a signal that polymorphism is missing.

```kotlin
// ❌ Closed for extension — must modify to add a new pricing rule
class PriceCalculator {
    fun calculate(purchase: Purchase): Double {
        val discount = when {
            RULE_1 -> StandardPriceTable().discountFor(purchase.value)
            RULE_2 -> PremiumPriceTable().discountFor(purchase.value)
            // ... more rules = more modifications
        }
        val freight = Correios().calculateFor(purchase.city)
        return purchase.value * (1 - discount) + freight
    }
}

// ✅ Open for extension — new rules = new classes, zero modifications
interface PriceTable {
    fun discountFor(value: Double): Double
}

interface DeliveryService {
    fun calculateFor(city: String): Double
}

class PriceCalculator(
    private val priceTable: PriceTable,
    private val delivery: DeliveryService
) {
    fun calculate(purchase: Purchase): Double {
        val discount = priceTable.discountFor(purchase.value)
        val freight = delivery.calculateFor(purchase.city)
        return purchase.value * (1 - discount) + freight
    }
}
```

### The OO mindset shift

Think about designing strong abstractions and how pieces fit together **before** writing procedural implementation. When a new exercise type, payment method, or delivery rule appears, the compiler should guide the developer to implement the right interface — not a developer hunting through `if` chains.

---

## Pillar 4: Encapsulation

Encapsulation hides the **"how"** and exposes only the **"what"**. When business rules leak outside their owning class, a single business change forces updates across many files (Shotgun Surgery).

### Tell, Don't Ask

Give commands to objects instead of querying their state to make decisions for them.

```kotlin
// ❌ Asking: caller knows the rules
fun process(invoice: Invoice) {
    if (invoice.isClosed && invoice.value > 5000) {
        invoice.markAsImportant()
    }
}

// ✅ Telling: the object owns its rules
fun process(invoice: Invoice) {
    invoice.markAsImportantIfEligible()
}
```

### The Law of Demeter

Don't chain calls through deep object graphs. `billing.client.address.city` means you're coupled to the internal structure of three classes. If any intermediate structure changes, your code breaks.

```kotlin
// ❌ Violates Demeter — coupled to Billing, Client, and Address
val city = billing.getClient().getAddress().getCity()

// ✅ Respects Demeter — only talks to its direct neighbor
val city = billing.clientCity()
```

### Avoid anemic domain models

An anemic model has classes with only data (attributes + getters/setters) and separate "service" classes that manipulate them. This is procedural programming in disguise. **Combine data and behavior in the same class.**

```kotlin
// ❌ Anemic: Invoice is a data bag, ProcessadorDeBoletos owns the logic
class Invoice(var paid: Boolean = false, val payments: MutableList<Payment> = mutableListOf())

class BoletoProcessor {
    fun process(boletos: List<Boleto>, invoice: Invoice) {
        var total = 0.0
        for (boleto in boletos) {
            invoice.payments.add(Payment(boleto.value, PaymentMethod.BOLETO))
            total += boleto.value
        }
        if (total >= invoice.value) invoice.paid = true
    }
}

// ✅ Rich domain: Invoice owns its payment logic
class Invoice(private val value: Double) {
    private val payments = mutableListOf<Payment>()
    var paid: Boolean = false
        private set

    fun addPayment(payment: Payment) {
        payments.add(payment)
        if (payments.sumOf { it.value } >= value) {
            paid = true
        }
    }
}

class BoletoProcessor {
    fun process(boletos: List<Boleto>, invoice: Invoice) {
        for (boleto in boletos) {
            invoice.addPayment(Payment(boleto.value, PaymentMethod.BOLETO))
        }
    }
}
```

### Getters and setters erode encapsulation

- Avoid setters — use descriptive methods like `withdraw()`, `deposit()`, `close()`
- Don't return mutable internal collections — return `Collections.unmodifiableList()` or Kotlin's `List` (read-only view) to force clients through encapsulated methods

---

## Pillar 5: Inheritance, LSP & Interface Segregation (ISP)

### Liskov Substitution Principle (LSP)

Subclasses must be **substitutable** for their base classes without breaking correctness.

- **Pre-conditions** can only be **relaxed** (accept more, never less)
- **Post-conditions** can only be **tightened** (guarantee more, never less)

A subclass that throws `UnsupportedOperationException` for an inherited method is **violating LSP** — it's refusing a contract it inherited.

### Favor composition over inheritance

Inheritance creates the strongest form of coupling. The child is intimately tied to the parent's internals. Prefer composition:

```kotlin
// ❌ Inheritance abuse: StudentAccount can't earn interest but inherits it
open class CommonAccount {
    open fun earnInterest() { /* calculates interest */ }
}

class StudentAccount : CommonAccount() {
    override fun earnInterest() {
        throw UnsupportedOperationException("Students don't earn interest")
    }
}

// ✅ Composition: shared balance handling, different capabilities
class BalanceHandler { /* deposit, withdraw, getBalance */ }

class CommonAccount(private val balance: BalanceHandler) {
    fun earnInterest() { /* uses balance */ }
}

class StudentAccount(private val balance: BalanceHandler) {
    // No earnInterest method — no broken contract
}
```

### Interface Segregation Principle (ISP)

No client should be forced to depend on methods it doesn't use. Fat interfaces lead to dummy implementations and `UnsupportedOperationException` — a direct LSP violation.

```kotlin
// ❌ Fat interface: not all taxes generate invoices
interface Tax {
    fun calculate(value: Double): Double
    fun generateInvoice(value: Double): Invoice  // IXMX doesn't do this!
}

// ✅ Segregated: each concern is a separate interface
interface TaxCalculator {
    fun calculate(value: Double): Double
}

interface InvoiceGenerator {
    fun generateInvoice(value: Double): Invoice
}
```

### Tiny Types for lean parameters

Instead of passing a complex `Invoice` object to a tax calculator (which exposes customer, address, payments — all irrelevant), extract a minimal interface:

```kotlin
interface Taxable {
    fun taxableItems(): List<Item>
}

class TaxCalculator {
    fun calculate(taxable: Taxable): Double =
        taxable.taxableItems().sumOf { it.value * 0.02 }
}
```

Now `Invoice`, `Billing`, or any other class can implement `Taxable` — maximum reuse, minimum coupling.

---

## Pillar 6: Object Consistency

### Born Valid — Rich Constructors

An object should never exist in an invalid state. Demand all required dependencies at construction time.

```kotlin
// ❌ Empty constructor + setters = invalid object exists
class Order {
    var customer: Customer? = null
    var items: MutableList<Item>? = null
}

// ✅ Rich constructor = Born Valid
class Order(
    val customer: Customer,
    private val items: MutableList<Item> = mutableListOf()
) {
    init {
        require(customer.isActive) { "Cannot create order for inactive customer" }
    }

    fun addItem(item: Item) { items.add(item) }
    fun items(): List<Item> = items.toList()  // immutable view
}
```

For frameworks that require a default constructor (e.g., Hibernate), provide one with `protected` visibility and mark it `@Deprecated`.

### The Good Neighbor Theorem

A "good neighbor" object never passes invalid or null data to another. By honoring this contract, you eliminate defensive `if (x != null)` checks throughout business logic. Use `Optional` or Kotlin's nullable types with explicit contracts to make absence visible.

### Immutability for Value Objects

Value objects (dates, addresses, CPFs, money amounts) should be immutable:

1. No setter methods
2. All properties `val` (final)
3. Modification methods return a **new instance**

```kotlin
// ✅ Immutable value object
data class Money(val amount: BigDecimal, val currency: Currency) {
    fun add(other: Money): Money {
        require(currency == other.currency) { "Cannot add different currencies" }
        return Money(amount + other.amount, currency)
    }
}
```

Entities (Order, Customer) are mutable — they have a lifecycle. But mutations should go through encapsulated methods, never setters.

### Naming: Intent over Implementation

- Describe the **"what"** (intent), not the **"how"** (implementation)
- Follow team and language conventions consistently
- Avoid both ultra-short names and excessively verbose ones

---

## Design Smell Quick-Reference

| Smell | Root Cause | What to look for |
|-------|-----------|------------------|
| **Feature Envy** | Low cohesion | A method uses another object's data more than its own |
| **God Class** | High coupling | 30+ dependencies; a class that "does everything" |
| **Divergent Changes** | Low cohesion / SRP | One file changes for multiple unrelated reasons |
| **Shotgun Surgery** | Tight coupling | One business change requires edits in 10+ files |
| **Refused Bequest** | Broken LSP | Subclass throws exceptions for inherited methods |
| **Inappropriate Intimacy** | Broken encapsulation | Class knows another's internal rules and thresholds |

For detailed detection heuristics and refactoring strategies, read [design_smells.md](references/design_smells.md).

For before/after code examples organized by pillar, read [before_after_examples.md](references/before_after_examples.md).

---

## Architectural Boundary Classes

Some classes will inherently look "procedural" — Adapters, Controllers, Factories. This is acceptable as long as:

- They live at the **edges** of the system (architectural boundaries)
- They contain **no business logic**
- The **core domain** remains clean and rich

### Factories vs. Dependency Injection

- **Factories**: Pure OO solution, explicit control, acceptable coupling since they're infrastructure with no business rules
- **DI Frameworks**: Great for large systems, but can hide complexity — watch for God Classes forming behind the scenes

---

## How to Apply This Skill

When writing or reviewing code, run through these diagnostic questions:

1. **Cohesion**: Does this class have more than one reason to change?
2. **Coupling**: Am I depending on a concrete class that is likely to change? Could I depend on an abstraction instead?
3. **OCP**: Am I adding behavior via `if`/`when` chains? Could I use polymorphism?
4. **Encapsulation**: Am I asking for data to make a decision, or telling the object to act? Am I chaining calls through deep object graphs?
5. **LSP**: Would substituting a subclass break calling code? Am I forcing a class to implement methods it doesn't need?
6. **Consistency**: Can this object be instantiated in an invalid state? Am I passing null where I shouldn't?
