# Design Smells — Detection & Refactoring Guide

A catalog of the 6 most common OO design smells, based on Chapter 9 of *"Orientação a Objetos e SOLID para Ninjas"*.

---

## 1. Refused Bequest

**Definition**: A subclass inherits from a parent but "refuses" or has no use for behaviors it receives.

**Principle Violated**: LSP (Liskov Substitution Principle)

**Detection Heuristics**:
- A subclass overrides a method to throw `UnsupportedOperationException` or return a no-op
- A method body is just `TODO()` or an empty block
- The "is-a" relationship doesn't hold semantically — e.g., `NotaFiscal extends Matematica`
- A subclass uses inheritance purely to access utility methods from the parent

**Refactoring Strategy**:
1. Identify whether a genuine "is-a" relationship exists
2. If not, **replace inheritance with composition** — inject the needed functionality as a dependency
3. If the parent has some methods that don't apply to all children, **extract an interface** for the common subset and have each subclass implement only what it needs

```kotlin
// ❌ Refused Bequest
open class Matematica {
    fun square(a: Int): Int = a * a
    fun sqrt(a: Int): Double = kotlin.math.sqrt(a.toDouble())
}

class NotaFiscal : Matematica() {
    // NotaFiscal IS NOT a type of Matematica!
    fun calculateTax(): Double = square(this.value).toDouble()
}

// ✅ Use composition instead
class MathHelper {
    fun square(a: Int): Int = a * a
}

class NotaFiscal(private val math: MathHelper) {
    fun calculateTax(): Double = math.square(this.value).toDouble()
}
```

---

## 2. Feature Envy

**Definition**: A method seems more "interested" in the data of another object than in its own class's data.

**Principle Violated**: Cohesion and Encapsulation

**Detection Heuristics**:
- A method calls multiple getters on a single external object to perform calculations
- "Manager", "Gerenciador", "Processor" classes that drive domain objects like puppets
- The method could be moved to the other class and it would make more sense there
- Vague class names that serve as dumping grounds for logic belonging elsewhere

**Refactoring Strategy**:
1. Identify which object's data the method is primarily manipulating
2. **Move the method** (or the relevant logic) to that object
3. The calling class should only *tell* the object to act, not *ask* for its data

```kotlin
// ❌ Feature Envy: Manager drives NotaFiscal like a puppet
class Manager {
    fun process(nf: NotaFiscal) {
        var tax = nf.calculateTax()
        if (nf.itemCount > 2) {
            tax *= 1.1  // logic about nf's data lives here
        }
        nf.setTaxValue(tax)
        nf.finalize()
    }
}

// ✅ Logic belongs inside NotaFiscal
class NotaFiscal {
    fun calculateFinalTax(): Double {
        val base = calculateTax()
        return if (itemCount > 2) base * 1.1 else base
    }

    fun finalizeWithTax() {
        taxValue = calculateFinalTax()
        finalize()
    }
}
```

---

## 3. Inappropriate Intimacy

**Definition**: A class knows too much about the internal decision-making process of another class.

**Principle Violated**: Encapsulation and "Tell, Don't Ask"

**Detection Heuristics**:
- A caller checks multiple conditions on another object's state before acting: `if (nf.isClosed && nf.value > 5000)`
- Magic numbers or thresholds that belong inside the domain object appear in external code
- Changes to internal business rules force "hunting" through callers to update logic

**Refactoring Strategy**:
1. **Encapsulate the decision** inside the owning object as a single, semantic method
2. The caller should issue a command, not reconstruct the internal rule

```kotlin
// ❌ Intimate: caller knows the exact rules
fun process(invoice: Invoice) {
    if (invoice.isClosed && invoice.value > 5000) {
        invoice.markAsImportant()
    }
}

// ✅ Encapsulated: the object owns its rules
// Inside Invoice class:
fun markAsImportantIfEligible() {
    if (isClosed && value > 5000) {
        markAsImportant()
    }
}

// Caller:
fun process(invoice: Invoice) {
    invoice.markAsImportantIfEligible()
}
```

---

## 4. God Class

**Definition**: A class that has grown to control too many other objects, accumulating disproportionate responsibilities.

**Principle Violated**: Cohesion (Low) and Coupling (High)

**Detection Heuristics**:
- Constructor with 10+ dependencies
- The class is hundreds or thousands of lines long
- Multiple developers frequently merge-conflict on the same file
- Virtually impossible to test in isolation
- The class name is vague: `ApplicationManager`, `MainService`, `Helper`

**Refactoring Strategy**:
1. Identify **clusters of related fields and methods** within the God Class
2. Extract each cluster into its own cohesive class
3. The God Class becomes a thin **coordinator** that delegates to the extracted classes
4. Apply DIP — depend on abstractions of the extracted classes

---

## 5. Divergent Changes

**Definition**: A single class is forced to change for multiple, unrelated reasons.

**Principle Violated**: Cohesion and Single Responsibility Principle (SRP)

**Detection Heuristics**:
- You modify the same file because a business rule changed AND because a database schema changed
- The class handles both domain logic and infrastructure concerns
- Different developers edit the same file for unrelated features

**Refactoring Strategy**:
1. Identify the **distinct reasons for change** (e.g., business rule vs. persistence vs. presentation)
2. Extract each concern into its own class
3. The original class should do only one thing — or become a coordinator

---

## 6. Shotgun Surgery

**Definition**: A single business change requires small edits scattered across many different classes.

**Principle Violated**: Coupling (High) and Encapsulation (Poor)

**Detection Heuristics**:
- Changing a business rule requires editing 5+ files
- The same conditional logic (e.g., `if (type == "PREMIUM")`) appears in multiple classes
- CTRL+F / search for a term returns dozens of matches across the codebase
- Logic that should be in one place has "leaked" into callers

**Refactoring Strategy**:
1. **Centralize the scattered logic** into the class that owns the concept
2. Other classes should depend on the centralized version through a single method call
3. Apply encapsulation — the "how" should live in one place, callers only know the "what"

---

## Summary Table

| Smell | Root Cause | Consequence | First Refactoring Move |
|-------|-----------|-------------|----------------------|
| Refused Bequest | Broken LSP / Inheritance | Confusing hierarchies | Replace inheritance with composition |
| Feature Envy | Low Cohesion | Procedural "data bucket" code | Move method to the data's owner |
| Inappropriate Intimacy | Broken Encapsulation | Shotgun updates | Encapsulate decision in owning class |
| God Class | High Coupling | Extreme fragility | Extract cohesive clusters into classes |
| Divergent Changes | Low Cohesion / SRP | High cognitive load | Separate concerns into distinct classes |
| Shotgun Surgery | Tight Coupling | Missed edits → bugs | Centralize leaked logic |
