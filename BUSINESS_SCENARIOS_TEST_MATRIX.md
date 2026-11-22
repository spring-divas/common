# Матриця бізнес-сценаріїв та їхнього тестування в проєкті Feedo (spring-divas)

Цей документ містить повний реєстр усіх бізнес-сценаріїв мікросервісної платформи **Feedo**, перелік задіяних сервісів, протоколів міжсервісної взаємодії та детальну інформацію про те, як і де кожен сценарій протестований (Unit, Integration, Contract, Chaos / Resilience).

---

## 1. Загальна таблиця бізнес-сценаріїв системи

| № | Бізнес-сценарій | Сервіси | Взаємодія | Тип тесту | Тестовий файл та метод | Опис перевірки |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **BS-01** | **Реєстрація клієнта (Customer)** | `user-service` | REST (Вхідний) | **Unit** | `UserServiceImplTest`<br>`create_shouldSaveAndReturnDto` | Перевірка хешування пароля через BCrypt, валідації полів, присвоєння ролі `CUSTOMER` та збереження у базі. |
| **BS-02** | **Автентифікація та отримання JWT** | `user-service` | REST (Вхідний) | **Unit** | `AuthServiceTest`<br>`authenticate_shouldGenerateTokenForCustomer`<br>`authenticate_shouldIncludeVenueRolesForManager` | Перевірка верифікації пароля, генерації підписаного JWT-токена з ролями користувача (CUSTOMER, MANAGER, ADMIN). |
| **BS-03** | **Керування алергіями клієнта** | `user-service` | REST | **Unit** | `UserAllergyServiceImplTest`<br>`hasAnyAllergy_shouldReturnTrueWhenMatch`<br>`create_shouldSaveAllergy` | Перевірка збереження списку алергій та детекції конфліктів інгредієнтів. |
| **BS-04** | **Призначення менеджера закладу** | `user-service` | REST | **Unit** | `VenueManagerServiceImplTest`<br>`create_shouldSaveManager`<br>`create_shouldThrowWhenManagerExists` | Верифікація зв'язку менеджера з `venueId`, перевірка унікальності призначення. |
| **BS-05** | **Створення та редагування закладу** | `venue-and-menu-service` | REST | **Unit** | `VenueServiceImplTest`<br>`create_shouldReturnSavedDto`<br>`update_shouldUpdateAndReturnDto` | Перевірка створення закладу, оновлення адреси та назви, валідація DTO як Java Records. |
| **BS-06** | **Створення категорій страв** | `venue-and-menu-service` | REST | **Unit** | `CategoryServiceImplTest`<br>`create_shouldReturnSavedDto`<br>`getAll_shouldReturnAllCategories` | Перевірка ізоляції категорій за `venueId` та каскадного отримання. |
| **BS-07** | **Налаштування інгредієнтів та алергенів** | `venue-and-menu-service` | REST | **Unit** | `IngredientServiceImplTest`<br>`update_shouldUpdateFieldsAndAllergens`<br>`AllergenServiceImplTest` | Перевірка прив'язки алергенів до інгредієнтів та валідації їхньої наявності у базі. |
| **BS-08** | **Створення страви (Transactional Outbox)** | `venue-and-menu-service` | DB Transaction + Outbox | **Integration** | `DishOutboxTests`<br>`createDishGeneratesOutboxRecordInSameTransaction` | Верифікація атомарного збереження страви та створення запису події у таблиці `outbox_event` в одній транзакції `@Transactional`. |
| **BS-09** | **Публікація подій зміни страв у Kafka** | `venue-and-menu-service` | Apache Kafka (`dish-events`) | **Integration** | `KafkaIntegrationTests`<br>`shouldPublishEventsInOrder` | Перевірка вичитування необроблених Outbox-подій шедулером та публікації у топік Kafka зі збереженням хронології. |
| **BS-10** | **Синхронізація репліки страв у сервісі замовлень** | `venue-and-menu-service` &rarr; `order-service` | Kafka Consumer | **Integration** | `order-service`:<br>`DishEventListenerIntegrationTest` | Споживання повідомлення з топіка `dish-events` сервісом замовлень та локальне оновлення read-моделі страв. |
| **BS-11** | **Генерація динамічного PDF-меню** | `venue-and-menu-service` | Внутрішній рендеринг | **Integration** | `DishRatingUpdateTests`<br>`VenueAndMenuServiceApplicationTests` | Перевірка групування страв за категоріями, HTML-шаблонізації Thymeleaf та експорту у PDF через iText. |
| **BS-12** | **Оформлення замовлення (Міжсервісна валідація)** | `order-service` &rarr; `user-service`<br>`order-service` &rarr; `venue-service` | Spring RestClient `@HttpExchange` | **Integration / Unit** | `OrderServiceImplTest`<br>`OrderControllerIntegrationTest` | `order-service` звертається до `user-service` для перевірки існування клієнта та до `venue-service` для перевірки цін та доступності страв. |
| **BS-13** | **Збереження замовлення та Outbox подія `ORDER_CREATED`** | `order-service` | DB Transaction + Outbox + Kafka | **Integration** | `OrderOutboxKafkaIntegrationTest`<br>`shouldPersistOrderAndProduceKafkaEvent` | Перевірка атомарного створення замовлення зі статусом `PENDING`, запису в outbox та відправки у топік `order-created`. |
| **BS-14** | **Передача контексту розподіленого трейсингу** | `order-service` &rarr; Kafka | OpenTelemetry, Trace Context | **Integration** | `OrderOutboxTraceContextIntegrationTest`<br>`shouldPropagateTraceParentToKafkaHeaders` | Верифікація інжекції заголовка `traceparent` (W3C Trace Context, `traceId`, `spanId`) у Kafka-заголовки повідомлення. |
| **BS-15** | **Оплата замовлення з перевіркою ідемпотентності** | `payment-service` | REST (Зовнішній) | **Integration** | `PaymentControllerIntegrationTest`<br>`shouldProcessPaymentWithIdempotencyKey`<br>`shouldReturnProblemDetailWhenIdempotencyKeyIsMissing` | Перевірка обов'язкового заголовка `Idempotency-Key`. Повторний запит повертає кешовану попередню відповідь без повторного списання. |
| **BS-16** | **Міжсервісна оплата через gRPC стрімінг** | `order-service` &harr; `payment-service` | Protocol Buffers, gRPC Bi-directional | **Integration** | `PaymentGrpcClientTest`<br>`shouldCompletePaymentViaGrpcStream`<br>`OrderControllerGrpcIntegrationTest` | Двосторонній обмін повідомленнями через gRPC: клієнт відправляє `OrderPaymentInfo`, сервер повертає статус, клієнт підтверджує через `PaymentConfirmation`, статус замовлення змінюється на `PAID`. |
| **BS-17** | **Контрактна сумісність між сервісами (Pact)** | `order-service` &rarr; `payment-service` | REST Contract (Pact) | **Contract** | `OrderPaymentConsumerPactTest`<br>`shouldMatchPactSpecification` | Автоматизована перевірка того, що схема HTTP-відповіді сервісу оплати відповідає очікуванням сервісу замовлень на етапі збірки. |
| **BS-18** | **Залишення відгуку з верифікацією замовлення** | `review-service` &rarr; `order-service` | Synchronous REST через `ResilientOrderClient` | **Unit** | `DishReviewServiceImplTest`<br>`create_shouldSaveReviewAndPublishEventWhenOrdered`<br>`create_shouldThrowWhenUserHasNotOrderedDish` | `review-service` запитує в `order-service` історію замовлень. Якщо користувач не замовляв цю страву, викидається `DishNotOrderedException` (бізнес-правило). |
| **BS-19** | **Синхронізація рейтингу через gRPC** | `review-service` &rarr; `venue-service` | gRPC Unary Client-Server | **Integration** | `RatingSyncGrpcServiceTests`<br>`shouldSyncRatingToVenueService` | При публікації відгуку розраховується середній рейтинг та передається через gRPC у `venue-and-menu-service` для миттєвого оновлення закладу/страви. |
| **BS-20** | **Стійкість до збоїв: спрацювання Circuit Breaker (Failure Storm)** | `order-service` &rarr; `venue-service` | Resilience4j Circuit Breaker | **Resilience / Chaos** | `ResilienceVenueClientTest`<br>`shouldOpenCircuitBreakerOnFailureStorm` | Серія збоїв зовнішнього сервісу переводить Circuit Breaker зі стану `CLOSED` у `OPEN`. |
| **BS-21** | **Стійкість до збоїв: штучна затримка мережі та активація Fallback** | `order-service` &rarr; `payment-service` | Resilience4j Timeout, CB, Fallback | **Resilience / Chaos** | `ResiliencePaymentClientTest`<br>`shouldOpenCircuitBreakerAndUseFallbackOnNetworkDelay` | **Тест зі штучною затримкою мережі WireMock (3500ms > таймаут 3s).** Верифікує перехід у стан `OPEN` та повернення Fallback-відповіді (статус `PENDING`) замість падіння чи 500 помилки. |
| **BS-22** | **Обмеження швидкості запитів (Rate Limiter)** | Всі сервіси / Ingress | Resilience4j RateLimiter & NGINX Ingress | **Unit / Integration** | `GlobalExceptionHandlerTest`<br>`OrderControllerIntegrationTest` | При перевищенні допустимої частоти запитів спрацьовує Rate Limiter, повертаючи стандартизовану відповідь RFC 7807 із HTTP 429 Too Many Requests. |
| **BS-23** | **Стандартизована обробка помилок валідації (RFC 7807)** | Всі 5 сервісів | Spring ProblemDetail | **Unit / Integration** | `GlobalExceptionHandlerTest` (усі сервіси),<br>`PaymentControllerIntegrationTest` | Перевірка обов'язкових полів DTO. Повернення структурованого JSON `application/problem+json` з мапою некоректних полів у `errors`. |

---

## 2. Відповідність 10 темам навчального курсу

1. **Тема 1: Поділ на Bounded Contexts, патерн Database-per-Service:**
   - 5 сервісів (`user-service`, `venue-and-menu-service`, `order-service`, `payment-service`, `review-service`), кожен з яких взаємодіє виключно зі своєю базою даних PostgreSQL/H2 (`user-db`, `venue-db`, `order-db`, `payment-db`, `review-db`).
2. **Тема 2: Multi-stage Dockerfile для Java 25, запуск від non-root:**
   - Кожен сервіс має оптимізований Dockerfile із розділенням на stage збірки (Gradle) та stage виконання (`distroless/java25-debian13:nonroot` або `eclipse-temurin:25`), що запускається від `USER 10001:10001`.
3. **Тема 3: Внутрішня мережева ізоляція, налаштовані Health Probes:**
   - Для кожного пода в k8s налаштовано `livenessProbe` та `readinessProbe` на ендпоінти Spring Boot Actuator (`/actuator/health/liveness`, `/actuator/health/readiness`).
4. **Тема 4: Стандартизовані відповіді помилок ProblemDetail, незмінні DTO Java Records:**
   - Усі вхідні та вихідні DTO переписані на Java Records. Всі винятки централізовано перехоплюються `GlobalExceptionHandler` і транслюються в RFC 7807 `ProblemDetail`.
5. **Тема 5: Apache Kafka, патерн Transactional Outbox:**
   - Реалізовано у `venue-and-menu-service` (топік `dish-events`) та `order-service` (топік `order-created`) з гарантією At-Least-Once Delivery та збереженням у таблиці `outbox_event` в межах локальної `@Transactional`.
6. **Тема 6: Експорт метрик у Prometheus, Micrometer, структуроване JSON-логування з MDC:**
   - Увімкнено `logstash-logback-encoder`, логи генеруються у форматі JSON з полями `service`, `traceId`, `spanId`. Метрики експортуються через Micrometer Prometheus.
7. **Тема 7: Розподілений трейсинг, кореляція traceId та spanId у логах:**
   - Реалізовано через Spring Boot OpenTelemetry Starter та `CorrelationIdInterceptor`. Заголовки `X-Correlation-Id` та `traceparent` автоматично прокидаються у REST та Kafka-запити.
8. **Тема 8: Rate Limiter, захист міжсервісних викликів Resilience4j Circuit Breaker:**
   - Налаштовано Rate Limiter з поверненням HTTP 429. Виклики між сервісами захищені Circuit Breaker, Retry та Bulkhead з Fallback-методами.
9. **Тема 9: Protobuf-схеми (.proto), робочий gRPC-сервер та gRPC-клієнт:**
   - Двоспрямований gRPC-стрімінг `payment.proto` між `order-service` та `payment-service`.
   - gRPC-клієнт/сервер `rating.proto` між `review-service` та `venue-and-menu-service`.
10. **Тема 10: Інтеграційні тести, тест відмовостійкості, контрактні тести:**
    - Тести з embedded Kafka, H2 та WireMock.
    - Тест стійкості зі штучною затримкою мережі (`ResiliencePaymentClientTest`).
    - Контрактні тести Pact (`OrderPaymentConsumerPactTest`).
