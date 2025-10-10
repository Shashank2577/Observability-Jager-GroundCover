package com.acme.orders.web;

import com.acme.observability.annotation.OtelSpan;
import com.acme.observability.logging.ObservabilityHelper;
import com.acme.orders.domain.OrderEntity;
import com.acme.orders.service.OrderService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("/orders")
public class OrdersController {

    private final OrderService service;
    private static final Logger logger = LoggerFactory.getLogger(OrdersController.class);

    public OrdersController(OrderService service) { this.service = service; }

    @PostMapping
    @OtelSpan("OrdersController.create")
    public ResponseEntity<OrderEntity> create(@RequestParam(name = "sku") String sku, @RequestParam(name = "qty") int qty) {
        logger.info("Received create order request: sku={}, qty={}", sku, qty);
        ObservabilityHelper.logWithAttributes("creating order", Map.of("sku", sku, "qty", qty, "operation", "create_order"));
        return ResponseEntity.ok(service.place(sku, qty));
    }

    @PostMapping("/batch")
    @OtelSpan("OrdersController.createBatch")
    public ResponseEntity<List<OrderEntity>> createBatch(@RequestBody List<Map<String, Object>> orders) {
        ObservabilityHelper.logWithAttributes("creating batch orders", Map.of("order_count", orders.size(), "operation", "create_batch_orders"));
        return ResponseEntity.ok(service.placeBatch(orders));
    }

    @GetMapping
    @OtelSpan("OrdersController.list")
    public List<OrderEntity> list() { 
        ObservabilityHelper.logWithAttributes("listing orders", Map.of("operation", "list_orders"));
        return service.list(); 
    }

    @GetMapping("/{id}")
    @OtelSpan("OrdersController.getById")
    public ResponseEntity<OrderEntity> getById(@PathVariable String id) {
        ObservabilityHelper.logWithAttributes("getting order by id", Map.of("order_id", id, "operation", "get_order_by_id"));
        Optional<OrderEntity> order = service.findById(id);
        return order.map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/sku/{sku}")
    @OtelSpan("OrdersController.getBySku")
    public List<OrderEntity> getBySku(@PathVariable String sku) {
        ObservabilityHelper.logWithAttributes("getting orders by sku", Map.of("sku", sku, "operation", "get_orders_by_sku"));
        return service.findBySku(sku);
    }

    @GetMapping("/stats")
    @OtelSpan("OrdersController.getStats")
    public Map<String, Object> getStats() {
        ObservabilityHelper.logWithAttributes("getting order statistics", Map.of("operation", "get_order_stats"));
        return service.getOrderStats();
    }

    @GetMapping("/health")
    @OtelSpan("OrdersController.health")
    public Map<String, Object> health() { 
        ObservabilityHelper.logWithAttributes("health check", Map.of("operation", "health_check"));
        return Map.of("status", "OK", "service", "orders-service", "version", "1.11.0");
    }

    @GetMapping("/metrics")
    @OtelSpan("OrdersController.metrics")
    public Map<String, Object> metrics() {
        ObservabilityHelper.logWithAttributes("getting metrics", Map.of("operation", "get_metrics"));
        return service.getMetrics();
    }
}
