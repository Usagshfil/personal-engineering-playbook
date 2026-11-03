# 01. Layered (N-Tier) Architecture

---

## 1. Definition
**Layered Architecture** (also known as N-Tier Architecture) organizes an application into horizontal layers, where each layer has a specific role and only depends on the layer directly beneath it. The standard arrangement consists of:
1. **Presentation Layer** (UI, Activities, Compose screens, ViewModels).
2. **Business / Domain Layer** (Core business logic, calculations, rules).
3. **Data / Persistence Layer** (Database, Network API, SharedPreferences/DataStore).

---

## 2. Purpose
Without layers, code collapses into a "Big Ball of Mud" where database SQL queries, UI rendering, and business calculations are mixed into a single 1,500-line file. Layered architecture enforces **separation of concerns** by restricting communication to unidirectional vertical boundaries.

---

## 3. Why It Matters
*   **Cognitive Clarity**: Developers instinctively know where to look: UI bugs are in the Presentation layer, calculation bugs are in the Business layer, and query bugs are in the Data layer.
*   **Low Barrier to Entry**: It is the simplest, most intuitive architectural pattern for intermediate engineers to master before tackling more abstract architectures like Clean or Hexagonal.

---

## 4. When to Use It
*   **Small to Mid-Scale Applications**: Ideal for straightforward mobile apps, CRUD applications, and utility tools.
*   **Prototyping & MVPs**: Provides clean separation without the cognitive overhead of multiple domain mappers and use-case classes.

---

## 5. When NOT to Use It (Anti-Complexity Limits)
*   **Complex Multi-Team Enterprise Systems**: As an app grows to dozens of engineers, strict top-down layers can lead to bottlenecks where any new feature requires simultaneous edits across all horizontal layers.
*   **Trivial Single-Screen Scripts**: A 50-line utility script does not need 3 separate layers.

---

## 6. Advantages & Disadvantages

| Advantages | Disadvantages / Trade-offs |
| :--- | :--- |
| **Intuitive & Standard**: Every software engineer understands it. | **Sinkhole Anti-Pattern**: Simple CRUD requests pass straight through layers without doing any work. |
| **Clear Separation**: UI code never touches SQL or network directly. | **Tight Horizontal Coupling**: Changes to the database table schema can ripple up through all layers. |
| **Easy Unit Testing**: Business layer can be tested with mock data layer. | **Not Domain-Centric**: Focuses on technical layers rather than business domains. |

---

## 7. Practical Examples

```
+-------------------------------------------------------------+
| Presentation Layer (Compose Screens, ViewModels, State)      |
+-------------------------------------------------------------+
                              │ (calls down)
                              ▼
+-------------------------------------------------------------+
| Business / Domain Layer (OrderValidator, DiscountCalculator) |
+-------------------------------------------------------------+
                              │ (calls down)
                              ▼
+-------------------------------------------------------------+
| Data Layer (Room Database, Retrofit Network Client)         |
+-------------------------------------------------------------+
```

### Kotlin Implementation Example
```kotlin
// 1. Data Layer: Direct database abstraction
class OrderDao(private val db: AppDatabase) {
    fun fetchOrder(id: String): OrderEntity = db.query("SELECT * FROM orders WHERE id = ?", id)
}

// 2. Business Layer: Pure domain rules
class OrderService(private val orderDao: OrderDao) {
    fun calculateFinalPrice(orderId: String): Double {
        val order = orderDao.fetchOrder(orderId)
        val discount = if (order.isVip) 0.15 else 0.0
        return order.subtotal * (1.0 - discount)
    }
}

// 3. Presentation Layer: Exposing UI state
class OrderViewModel(private val orderService: OrderService) : ViewModel() {
    private val _price = MutableStateFlow<Double>(0.0)
    val price: StateFlow<Double> = _price.asStateFlow()

    fun loadPrice(orderId: String) {
        _price.value = orderService.calculateFinalPrice(orderId)
    }
}
```

---

## 8. Common Mistakes
1.  **Layer Skipping**: Presentation layer bypassing the Business layer to directly query the Database layer (`Activity` executing raw SQL queries).
2.  **Circular Layer Dependencies**: Data layer importing Presentation models or UI classes.
3.  **Leaking Database Entities to UI**: Exposing raw SQLite/Room entity classes directly to the UI layer, preventing the database schema from evolving independently.

---

## 9. Verification Checklist

- [ ] Does communication flow strictly downward (Presentation $\rightarrow$ Business $\rightarrow$ Data)?
- [ ] Is the presentation layer completely free of raw SQL queries or direct HTTP calls?
- [ ] Can the business logic layer be unit-tested without launching an Android emulator or UI test?
- [ ] Are database entities mapped to clean domain models before leaving the data layer?
- [ ] Are circular imports between packages prevented?
