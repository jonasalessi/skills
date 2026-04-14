# Before & After Code Examples

Curated transformations from bad to good OO design, organized by pillar. All examples in Kotlin.

---

## Pillar 1: Cohesion & SRP

### Example 1.1 — Salary Calculator (Ch.2)

```kotlin
// ❌ BEFORE: Non-cohesive — all rules in one class
class SalaryCalculator {
    fun calculate(employee: Employee): Double = when (employee.role) {
        Role.DEVELOPER -> tenOrTwentyPercent(employee)
        Role.DBA, Role.TESTER -> fifteenOrTwentyFivePercent(employee)
        else -> throw RuntimeException("Invalid employee")
    }

    private fun tenOrTwentyPercent(e: Employee): Double =
        if (e.baseSalary > 3000.0) e.baseSalary * 0.8 else e.baseSalary * 0.9

    private fun fifteenOrTwentyFivePercent(e: Employee): Double =
        if (e.baseSalary > 2000.0) e.baseSalary * 0.75 else e.baseSalary * 0.85
}
```

```kotlin
// ✅ AFTER: Each rule isolated behind an interface
interface CalculationRule {
    fun calculate(employee: Employee): Double
}

class TenOrTwentyPercent : CalculationRule {
    override fun calculate(employee: Employee): Double =
        if (employee.baseSalary > 3000.0) employee.baseSalary * 0.8
        else employee.baseSalary * 0.9
}

class FifteenOrTwentyFivePercent : CalculationRule {
    override fun calculate(employee: Employee): Double =
        if (employee.baseSalary > 2000.0) employee.baseSalary * 0.75
        else employee.baseSalary * 0.85
}

// The role enum holds its own rule — no if/when needed
enum class Role(val rule: CalculationRule) {
    DEVELOPER(TenOrTwentyPercent()),
    DBA(FifteenOrTwentyFivePercent()),
    TESTER(FifteenOrTwentyFivePercent())
}

class SalaryCalculator {
    fun calculate(employee: Employee): Double =
        employee.role.rule.calculate(employee)
}
```

### Example 1.2 — Fat Controller → Coordinator (Ch.2)

```kotlin
// ❌ BEFORE: Controller mixes business logic + infrastructure
@PostMapping("/invoice/new")
fun createInvoice(invoice: Invoice) {
    if (invoice.isValid()) {
        // Business rule inline
        if (invoice.isFromSaoPaulo()) invoice.doubleTaxes()

        // Email inline
        if (invoice.exceedsLimit()) {
            val smtp = SMTP()
            smtp.connect("smtp.server.com")
            smtp.send(invoice.clientEmail, "Alert", invoice.toString())
        }

        // Raw SQL inline
        val sql = "INSERT INTO invoices (...) VALUES (...)"
        connection.prepareStatement(sql).execute()

        // Web service inline
        val ws = SOAP()
        ws.send(invoice)
    }
}
```

```kotlin
// ✅ AFTER: Controller coordinates, doesn't compute
@PostMapping("/invoice/new")
fun createInvoice(invoice: Invoice): View {
    if (!invoice.isValid()) return view("validation-error")

    // Business rules are decorators/chain of responsibility
    val rules = DoubleTaxForSaoPaulo(EmailIfExceedsLimit())
    rules.apply(invoice)

    // Persistence via DAO
    invoiceDao.save(invoice)

    // Integration via dedicated service
    erpService.send(invoice)

    return view("success")
}
```

---

## Pillar 2: Coupling & DIP

### Example 2.1 — Invoice Generator (Ch.3)

```kotlin
// ❌ BEFORE: Coupled to concrete implementations
class InvoiceGenerator(
    private val emailSender: EmailSender,
    private val dao: InvoiceDao
) {
    fun generate(billing: Billing): Invoice {
        val value = billing.monthlyValue
        val invoice = Invoice(value, value * 0.06)
        emailSender.send(invoice)
        dao.persist(invoice)
        return invoice
    }
}
```

```kotlin
// ✅ AFTER: Coupled only to a stable abstraction
interface PostGenerationAction {
    fun execute(invoice: Invoice)
}

class EmailNotification : PostGenerationAction {
    override fun execute(invoice: Invoice) { /* send email */ }
}

class DatabasePersistence : PostGenerationAction {
    override fun execute(invoice: Invoice) { /* persist */ }
}

class SapIntegration : PostGenerationAction {
    override fun execute(invoice: Invoice) { /* send to SAP */ }
}

class InvoiceGenerator(
    private val actions: List<PostGenerationAction>
) {
    fun generate(billing: Billing): Invoice {
        val value = billing.monthlyValue
        val invoice = Invoice(value, value * 0.06)
        actions.forEach { it.execute(invoice) }
        return invoice
    }
}
```

---

## Pillar 3: OCP & Polymorphism

### Example 3.1 — Price Calculator (Ch.4)

```kotlin
// ❌ BEFORE: Must modify class to add new rules
class PriceCalculator {
    fun calculate(purchase: Purchase): Double {
        val freight = Correios()
        val discount = when {
            conditionA -> StandardPriceTable().discountFor(purchase.value)
            conditionB -> PremiumPriceTable().discountFor(purchase.value)
            // add more here → modify this class
        }
        val shippingCost = freight.calculateFor(purchase.city)
        return purchase.value * (1 - discount) + shippingCost
    }
}
```

```kotlin
// ✅ AFTER: Add new rules without touching this class
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

// New rule? Just create a new class:
class BlackFridayPriceTable : PriceTable {
    override fun discountFor(value: Double): Double =
        if (value > 500) 0.30 else 0.15
}
```

---

## Pillar 4: Encapsulation

### Example 4.1 — Invoice Processing (Ch.5)

```kotlin
// ❌ BEFORE: Processor knows invoice internals, anemic model
class BoletoProcessor {
    fun process(boletos: List<Boleto>, invoice: Invoice) {
        var total = 0.0
        for (boleto in boletos) {
            val payment = Payment(boleto.value, PaymentMethod.BOLETO)
            invoice.payments.add(payment)        // direct list access
            total += boleto.value
        }
        if (total >= invoice.value) {
            invoice.paid = true                   // exposing internal state
        }
    }
}
```

```kotlin
// ✅ AFTER: Invoice owns its payment logic
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

    private fun totalPayments(): Double = payments.sumOf { it.value }
}

class BoletoProcessor {
    fun process(boletos: List<Boleto>, invoice: Invoice) {
        for (boleto in boletos) {
            invoice.addPayment(Payment(boleto.value, PaymentMethod.BOLETO))
        }
    }
}
```

### Example 4.2 — Tax Calculation Encapsulation (Ch.5)

```kotlin
// ❌ BEFORE: Caller knows the tax threshold
fun calculateTax(invoice: Invoice) {
    if (invoice.valueBeforeTax > 10000) {
        val tax = 0.06 * invoice.value
        // ...
    }
}

// ✅ AFTER: Invoice hides the rule
val tax = invoice.calculateTax()
// Inside Invoice:
fun calculateTax(): Double =
    if (valueBeforeTax > 10000) 0.06 * value else 0.0
```

---

## Pillar 5: Inheritance, LSP & ISP

### Example 5.1 — Account Hierarchy (Ch.6)

```kotlin
// ❌ BEFORE: StudentAccount refuses parent's behavior (LSP violation)
open class CommonAccount(protected var balance: Double) {
    open fun earnInterest() {
        balance *= 1.01
    }
}

class StudentAccount(balance: Double) : CommonAccount(balance) {
    override fun earnInterest() {
        throw UnsupportedOperationException("Student accounts don't earn interest")
    }
}

// Client code breaks at runtime:
val accounts: List<CommonAccount> = listOf(CommonAccount(1000.0), StudentAccount(500.0))
accounts.forEach { it.earnInterest() } // 💥 crashes on StudentAccount
```

```kotlin
// ✅ AFTER: Composition, shared BalanceHandler
class BalanceHandler(private var balance: Double) {
    fun deposit(amount: Double) { balance += amount }
    fun withdraw(amount: Double) { balance -= amount }
    fun currentBalance(): Double = balance
}

class CommonAccount(private val handler: BalanceHandler) {
    fun earnInterest() {
        handler.deposit(handler.currentBalance() * 0.01)
    }
    fun deposit(amount: Double) = handler.deposit(amount)
    fun withdraw(amount: Double) = handler.withdraw(amount)
}

class StudentAccount(private val handler: BalanceHandler) {
    // No earnInterest — no broken contract
    fun deposit(amount: Double) = handler.deposit(amount)
    fun withdraw(amount: Double) = handler.withdraw(amount)
}
```

### Example 5.2 — Interface Segregation (Ch.7)

```kotlin
// ❌ BEFORE: Fat interface forces dummy implementations
interface Tax {
    fun calculate(value: Double): Double
    fun generateInvoice(value: Double): Invoice // not all taxes do this!
}

class IxmxTax : Tax {
    override fun calculate(value: Double): Double = value * 0.03
    override fun generateInvoice(value: Double): Invoice {
        throw UnsupportedOperationException("IXMX doesn't generate invoices")
    }
}
```

```kotlin
// ✅ AFTER: Segregated interfaces — each client depends only on what it uses
interface TaxCalculator {
    fun calculate(value: Double): Double
}

interface InvoiceGenerator {
    fun generateInvoice(value: Double): Invoice
}

class IssTax : TaxCalculator, InvoiceGenerator {
    override fun calculate(value: Double): Double = value * 0.05
    override fun generateInvoice(value: Double): Invoice = Invoice(value * 0.05)
}

class IxmxTax : TaxCalculator {
    override fun calculate(value: Double): Double = value * 0.03
    // No invoice generation — no broken contract
}
```

### Example 5.3 — Tiny Types (Ch.7)

```kotlin
// ❌ BEFORE: Calculator receives the whole complex object
class TaxCalculator {
    fun calculate(invoice: Invoice): Double {
        // Has access to invoice.customer, invoice.address, invoice.payments
        // Only needs invoice.items — inappropriate intimacy
        return invoice.items.sumOf { it.value * 0.02 }
    }
}

// ✅ AFTER: Minimal interface — maximum reuse
interface Taxable {
    fun taxableItems(): List<Item>
}

class TaxCalculator {
    fun calculate(taxable: Taxable): Double =
        taxable.taxableItems().sumOf { it.value * 0.02 }
}

// Now Invoice, Billing, or any other class can be Taxable
class Invoice : Taxable {
    override fun taxableItems(): List<Item> = items
}
```

---

## Pillar 6: Object Consistency

### Example 6.1 — Rich Constructor (Ch.8)

```kotlin
// ❌ BEFORE: Object born invalid
class Order {
    var customer: Customer? = null
    val items = mutableListOf<Item>()
}

// Usage: order exists without a customer!
val order = Order()
order.customer = someCustomer  // maybe, maybe not
```

```kotlin
// ✅ AFTER: Born Valid
class Order(val customer: Customer) {
    private val _items = mutableListOf<Item>()
    val items: List<Item> get() = _items.toList()

    init {
        require(customer.isActive) { "Cannot create order for inactive customer" }
    }

    fun addItem(item: Item) {
        _items.add(item)
    }
}
```

### Example 6.2 — Immutable Value Object (Ch.8)

```kotlin
// ❌ BEFORE: Mutable value object — side effects
class Money(var amount: BigDecimal, var currency: String) {
    fun add(other: Money) {
        this.amount = this.amount + other.amount  // mutates in place!
    }
}

val price = Money(BigDecimal("100"), "BRL")
val tax = Money(BigDecimal("10"), "BRL")
price.add(tax)  // price is now 110 — original value lost
```

```kotlin
// ✅ AFTER: Immutable — returns new instance
data class Money(val amount: BigDecimal, val currency: String) {
    fun add(other: Money): Money {
        require(currency == other.currency) { "Currency mismatch" }
        return Money(amount + other.amount, currency)
    }

    fun multiply(factor: Double): Money =
        Money(amount * BigDecimal.valueOf(factor), currency)
}

val price = Money(BigDecimal("100"), "BRL")
val total = price.add(tax)  // price unchanged, total is a new instance
```
