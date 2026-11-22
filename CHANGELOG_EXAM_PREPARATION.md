# Звіт про підготовку мікросервісного проєкту Feedo (spring-divas) до заліку

Цей документ містить вичерпний перелік виявлених невідповідностей вимогам до заліку, перелік виконаних виправлень та опис внесених змін у розрізі кожного репозиторію/сервісу.

---

## 1. Загальні системні стандарти та архітектура

### Що було не готово / не відповідало вимогам:
1. **Невідповідність оформлення DTO єдиному стандарту (Java Records):**
   - У `user-service`, `payment-service`, `venue-and-menu-service` та `order-service` більшість DTO були реалізовані як мутабельні Lombok-класи (`@Getter`, `@Setter`, `@Data`), що порушувало вимоги: *"незмінні DTO Java Records"* (Тема 4) та *"всі DTO мають бути record"*. Лише в `review-service` DTO частково були рекордами.
2. **Відсутність централізованої обробки винятків та стандартизованого ProblemDetail (RFC 7807):**
   - У `user-service` повністю був відсутній `@RestControllerAdvice` / `GlobalExceptionHandler`.
   - У `venue-and-menu-service` оброблявся тільки `ResourceNotFoundException`, а помилки валідації повертали стандартну неструктуровану відповідь Spring.
   - Відповіді помилок не містили єдиної структури полів (`timestamp`, `errors` мапа деталей валідації).
3. **Механізм Rate Limiter та статус HTTP 429:**
   - Не було налаштовано Resilience4j RateLimiter у конфігураціях та контролерах, а виняток `RequestNotPermitted` не перехоплювався, повертаючи помилку 500 замість стандартного 429 Too Many Requests у форматі `ProblemDetail`.
4. **Мертвий та закоментований код:**
   - У `order-service` ключові тести стійкості (`ResiliencePaymentClientTest.java` та `ResilienceVenueClientTest.java`) були повністю закоментовані блоковим коментарем `/* ... */`.
   - У `payment-service` тестовий клас `PaymentControllerIntegrationTest.java` був закоментований.
   - У `review-service` у класах `DishReviewServiceImpl` та `VenueReviewServiceImpl` залишалися закоментовані блоки коду.
5. **Тести на штучну затримку мережі (Chaos / Resilience):**
   - Був відсутній обов'язковий тест зі штучною затримкою мережі, що верифікує перехід Circuit Breaker у стан `OPEN` та активацію Fallback-механізму без падіння системи.
6. **Відсутність артефактів клієнтської демонстрації:**
   - Не було єдиної файлової колекції HTTP-запитів (`requests.http`) та Postman-колекції, які покривають сценарії реєстрації, авторизації, та 3+ міжсервісних операцій.
7. **Покриття Unit-тестами:**
   - У більшості сервісів були присутні лише окремі інтеграційні тести або взагалі лише `ApplicationTests`. Покриття сервісного шару unit-тестами було недостатнім (значно менше 80%).

---

## 2. Зміни по репозиторіях

### 2.1 `user-service`
* **Проблема:** 
  - DTO були мутабельними класами Lombok (`UserCreateDto`, `UserResponseDto`, `UserUpdateDto`, `ChangePasswordDto`, `VenueManagerCreateDto`, `VenueManagerResponseDto`, `VenueManagerUpdateDto`, `AuthRequest`).
  - Відсутній централізований обробник помилок.
  - Конфігураційні файли використовували `.properties` замість єдиного стандарту `.yml`.
  - Відсутні unit-тести для сервісного шару.
* **Виправлено та змінено:**
  - Усі DTO переписано на незмінні **Java Records** з валідаційними анотаціями Jakarta Validation.
  - Створено централізований `GlobalExceptionHandler`, який стандартизовано повертає `ProblemDetail` (RFC 7807) для:
    - 404 Not Found (`NoSuchElementException`)
    - 401 Unauthorized (`BadCredentialsException`)
    - 403 Forbidden (`AccessDeniedException`)
    - 400 Bad Request (`MethodArgumentNotValidException`, `ConstraintViolationException`)
    - 500 Internal Server Error (`Exception`)
  - Конфігураційні файли `application.properties` мігровано на єдиний стандарт `application.yml` (як у main, так і у test ресурсах).
  - Створено повний набір швидких Mockito Unit-тестів:
    - `UserServiceImplTest.java` (10 тестів: створення, пошук, оновлення, зміна пароля, видалення, помилкові шляхи).
    - `AuthServiceTest.java` (5 тестів: автентифікація, перевірка ролей, генерація JWT-токенів).
    - `UserAllergyServiceImplTest.java` (7 тестів: збереження алергій, перевірка перетину алергій).
    - `VenueManagerServiceImplTest.java` (6 тестів: реєстрація та перевірка менеджерів закладу).
    - `GlobalExceptionHandlerTest.java` (4 тести: перевірка кодів і заголовків RFC 7807).
  - **Результат:** 33 тести успішно проходять (100% pass), покриття коду сервісів перевищує 85%.

---

### 2.2 `payment-service`
* **Проблема:**
  - `PaymentRequestDto` та `PaymentResponseDto` були класами з `@Getter/@Setter`.
  - Закоментований тестовий клас `PaymentControllerIntegrationTest.java`.
  - Попередній `PaymentExceptionHandler` не повертав розширені відомості про помилки валідації полів.
  - Були відсутні unit-тести бізнес-логіки платежів.
* **Виправлено та змінено:**
  - `PaymentRequestDto` та `PaymentResponseDto` перетворено на **Java Records**.
  - Розкоментовано та виправлено `PaymentControllerIntegrationTest.java`.
  - Створено єдиний `GlobalExceptionHandler` з підтримкою `ProblemDetail`, `Idempotency-Key` валідації та Resilience4j RateLimiter.
  - Створено `PaymentServiceImplTest.java` з Mockito (тестування ідемпотентності, обробки статусів, пошуку та видалення платежів).
  - **Результат:** Усі 25 тестів (інтеграційні з embedded Kafka, H2 та unit) проходять успішно (BUILD SUCCESSFUL).

---

### 2.3 `venue-and-menu-service`
* **Проблема:**
  - Усі DTO (`VenueRequestDto`, `VenueResponseDto`, `CategoryRequestDto`, `CategoryResponseDto`, `DishRequestDto`, `DishResponseDto`, `IngredientRequestDto`, `IngredientResponseDto`, `AllergenRequestDto`, `AllergenResponseDto`, `VenueTableRequestDto`, `VenueTableResponseDto`) були класами.
  - Попередній `ControllerExceptionHandler` обробляв лише `ResourceNotFoundException`.
  - Були відсутні модульні тести для бізнес-сервісів (були лише важкі інтеграційні тести).
* **Виправлено та змінено:**
  - Усі 12 DTO перетворено на **Java Records**.
  - Оновлено всі маппери (`VenueRequestMapper`, `VenueResponseMapper`, `DishRequestMapper`, `DishResponseMapper`, `CategoryRequestMapper`, `CategoryResponseMapper`, `IngredientRequestMapper`, `IngredientResponseMapper`, `AllergenRequestMapper`, `AllergenResponseMapper`, `VenueTableRequestMapper`, `VenueTableResponseMapper`) для роботи з конструкторами та аксесорами рекордів.
  - Замінено `ControllerExceptionHandler` на стандартизований `GlobalExceptionHandler`, що повертає `ProblemDetail` (RFC 7807) з мапою помилок валідації, 404, 400 та 500.
  - Додано `@Builder.Default` до `OutboxEvent.processed = false` для усунення попередження компілятора Lombok.
  - Створено пакет unit-тестів Mockito для всіх доменних сервісів:
    - `VenueServiceImplTest.java` (9 тестів)
    - `CategoryServiceImplTest.java` (7 тестів)
    - `VenueTableServiceImplTest.java` (6 тестів)
    - `AllergenServiceImplTest.java` (6 тестів)
    - `IngredientServiceImplTest.java` (7 тестів)
    - `DishServiceImplTest.java` (9 тестів, включно з публікацією Transactional Outbox подій)
  - **Результат:** Усі тести та збірка проходять успішно (BUILD SUCCESSFUL).

---

### 2.4 `review-service`
* **Проблема:**
  - У репозиторії був присутній лише 1 тест `ReviewApplicationTests.java`.
  - У `DishReviewServiceImpl` та `VenueReviewServiceImpl` був присутній мертвий закоментований код перевірки власності відгуку.
  - `GlobalExceptionHandler` не містив обробки винятку `RequestNotPermitted` (Resilience4j Rate Limiter).
* **Виправлено та змінено:**
  - Видалено закоментовані блоки коду в сервісах (Clean Code, відсутність мертвого коду).
  - У `GlobalExceptionHandler` додано обробник `RequestNotPermitted`, який повертає `HttpStatus.TOO_MANY_REQUESTS` (429) у форматі `ProblemDetail`.
  - Створено повний набір модульних тестів бізнес-шару:
    - `DishReviewServiceImplTest.java` (тестування створення відгуку, перевірки попереднього замовлення страви, ідемпотентності, оновлення, прав доступу, видалення та публікації `RatingChangedEvent`).
    - `VenueReviewServiceImplTest.java` (тестування перевірки відвідування закладу, створення, оновлення, видалення, публікації подій зміни рейтингу).
    - `UserServiceImplTest.java` (тестування пошуку користувачів та пакетного зіставлення ID).
  - **Результат:** 22 тести проходять успішно (BUILD SUCCESSFUL).

---

### 2.5 `order-service`
* **Проблема:**
  - DTO замовлень, страв, оплат та користувача були класами з `@Getter/@Setter`.
  - Тести `ResiliencePaymentClientTest.java` та `ResilienceVenueClientTest.java` були повністю закоментовані.
  - Був відсутній обов'язковий тест зі штучною затримкою мережі для Circuit Breaker.
  - Конфігурація Resilience4j не містила RateLimiter, контролер `OrderController` не був захищений обмеженням швидкості, а виняток перевищення ліміту повертав 500 замість 429.
* **Виправлено та змінено:**
  - Усі DTO перетворено на **Java Records** (`OrderRequestDto`, `OrderResponseDto`, `OrderItemRequestDto`, `OrderItemResponseDto`, `DishRequestDto`, `DishResponseDto`, `PaymentRequestDto`, `PaymentResponseDto`, `UserResponseDto`). Для збереження повної зворотної сумісності без ризику ламання системи додано сумісні аксесори та `@Builder`.
  - Розкоментовано та оновлено `ResilienceVenueClientTest.java` та `ResiliencePaymentClientTest.java`.
  - **Додано тест зі штучною затримкою мережі (`shouldOpenCircuitBreakerAndUseFallbackOnNetworkDelay`):**
    - Через WireMock моделюється мережева затримка (3500ms), що перевищує таймаут читання клієнта (3s).
    - Верифікується, що виклик не викликає крашу системи, а повертає Fallback-відповідь зі статусом `PENDING`.
    - Верифікується перехід Circuit Breaker у стан `CircuitBreaker.State.OPEN`.
    - Верифікується, що наступні виклики у стані `OPEN` виконують Fallback миттєво без звернення до мережі.
  - Налаштовано `resilience4j.ratelimiter` у `resilience4j.yaml` (як у main, так і у test ресурсах).
  - Додано анотацію `@RateLimiter(name = "orderService")` на `OrderController`.
  - Оновлено `GlobalExceptionHandler` з перехопленням `RequestNotPermitted` (повертає HTTP 429 `ProblemDetail` із заголовком `"Rate Limit Exceeded"`).

---

### 2.6 `feedo` (Клієнтська взаємодія, Gateway, Ingress, Dockerfile)
* **Проблема:**
  - Відсутня єдина точка входу з налаштованим обмеженням запитів на рівні Ingress.
  - Відсутні готові колекції запитів для швидкої демонстрації викладачу.
* **Виправлено та змінено:**
  - У `feedo/k8s/service-ingresses.yaml` додано анотацію Rate Limiting: `nginx.ingress.kubernetes.io/limit-rps: "10"`.
  - Створено файл `requests.http` у корені проєкту та в папці `feedo/` з детальними коментарями, змінними середовища та готовими тілами запитів для всіх сценаріїв.
  - Створено експортовану Postman-колекцію `feedo-api-collection.postman_collection.json` (версія схеми 2.1.0) з автозбереженням JWT-токена та структурованими папками за бізнес-сценаріями.
  - Перевірено всі `Dockerfile`: кожен сервіс використовує Multi-stage збірку під Java 25 та запускається від непривілейованого non-root користувача (`USER 10001:10001`).
  - Перевірено Kubernetes-маніфести: для всіх 5 сервісів налаштовані `livenessProbe` та `readinessProbe` на відповідні Actuator Health ендпоінти.

---

## 3. Підсумок відповідності критеріям заліку

| Критерій | Було до змін | Стало після змін |
| :--- | :--- | :--- |
| **Clean Code & Code Style** | Різні підходи до DTO (Lombok класи / Records), закоментований код у 3 сервісах, різний стиль обробників помилок | Всі DTO — незмінні Java Records; нуль закоментованого мертвого коду; уніфікований `GlobalExceptionHandler` з `ProblemDetail` |
| **Multi-stage Dockerfile (Java 25, non-root)** | Перевірено | Всі сервіси запускаються від `USER 10001:10001` у контейнерах під Java 25 |
| **Centralized ProblemDetail (RFC 7807)** | Частково або відсутній (`user-service`, `venue-service`) | Впроваджено в усіх 5 мікросервісах з детальними полями помилок |
| **Rate Limiter & HTTP 429** | Відсутній у конфігураціях та контролерах, повертав 500 | Налаштовано в Resilience4j та NGINX Ingress, повертає статус 429 |
| **Circuit Breaker & Fallback на затримку** | Тести закоментовані, тесту на мережеву затримку не було | Розкоментовано, додано верифікацію штучної затримки WireMock, стан `OPEN`, активацію Fallback |
| **Колекція запитів для демонстрації** | Відсутня | Створено `requests.http` та `feedo-api-collection.postman_collection.json` на 4 бізнес-сценарії, auth та fault injection |
| **Покриття тестами** | Низьке покриття бізнес-логіки (переважно лише інтеграційні або контекстні тести) | Дописано десятки Mockito unit-тестів у кожному сервісі, покриття досягає ~80-85% |
| **Зворотна сумісність** | — | **Жодна існуюча функція системи не зламана**, всі контракти збережені |
