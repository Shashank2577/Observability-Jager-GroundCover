package com.acme.orders.service;

import com.acme.observability.annotation.OtelSpan;
import com.acme.observability.logging.ObservabilityHelper;
import com.acme.orders.domain.OrderEntity;
import com.acme.orders.repo.OrderRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class OrderService {

    private final OrderRepository repo;
    private final RestTemplate restTemplate;
    private final String inventoryBaseUrl;

    public OrderService(OrderRepository repo, RestTemplate restTemplate,
                        @Value("${inventory.base-url:http://inventory-service:8080}") String inventoryBaseUrl) {
        this.repo = repo;
        this.restTemplate = restTemplate;
        this.inventoryBaseUrl = inventoryBaseUrl;
    }

    @OtelSpan("OrderService.placeOrder")
    public OrderEntity place(String sku, int qty) {
        ObservabilityHelper.logWithAttributes("placing order", Map.of("sku", sku, "qty", qty, "operation", "place_order"));
        
        // Call inventory service to reserve stock
        String url = inventoryBaseUrl + "/inventory/reserve?sku=" + sku + "&qty=" + qty;
        ResponseEntity<String> resp = restTemplate.postForEntity(url, null, String.class);
        if (!resp.getStatusCode().is2xxSuccessful()) {
            ObservabilityHelper.logWithAttributes("inventory reserve failed", Map.of("sku", sku, "qty", qty, "status", resp.getStatusCode().toString()));
            throw new IllegalStateException("Inventory reserve failed: " + resp.getStatusCode());
        }
        
        OrderEntity e = OrderEntity.create(sku, qty);
        repo.save(e);
        ObservabilityHelper.logWithAttributes("order created successfully", Map.of("order.id", e.getId(), "sku", sku, "qty", qty, "operation", "order_created"));
        return e;
    }

    @OtelSpan("OrderService.placeBatch")
    public List<OrderEntity> placeBatch(List<Map<String, Object>> orders) {
        ObservabilityHelper.logWithAttributes("placing batch orders", Map.of("order_count", orders.size(), "operation", "place_batch_orders"));
        
        List<OrderEntity> createdOrders = orders.stream()
            .map(order -> {
                String sku = (String) order.get("sku");
                Integer qty = (Integer) order.get("qty");
                return place(sku, qty);
            })
            .collect(Collectors.toList());
            
        ObservabilityHelper.logWithAttributes("batch orders created", Map.of("created_count", createdOrders.size(), "operation", "batch_orders_created"));
        return createdOrders;
    }

    @OtelSpan("OrderService.list")
    public List<OrderEntity> list() {
        ObservabilityHelper.logWithAttributes("listing all orders", Map.of("operation", "list_all_orders"));
        List<OrderEntity> orders = repo.findAll();
        ObservabilityHelper.logWithAttributes("orders retrieved", Map.of("count", orders.size(), "operation", "orders_retrieved"));
        return orders;
    }

    @OtelSpan("OrderService.findById")
    public Optional<OrderEntity> findById(String id) {
        ObservabilityHelper.logWithAttributes("finding order by id", Map.of("order_id", id, "operation", "find_order_by_id"));
        Optional<OrderEntity> order = repo.findById(id);
        if (order.isPresent()) {
            ObservabilityHelper.logWithAttributes("order found", Map.of("order_id", id, "sku", order.get().getSku(), "operation", "order_found"));
        } else {
            ObservabilityHelper.logWithAttributes("order not found", Map.of("order_id", id, "operation", "order_not_found"));
        }
        return order;
    }

    @OtelSpan("OrderService.findBySku")
    public List<OrderEntity> findBySku(String sku) {
        ObservabilityHelper.logWithAttributes("finding orders by sku", Map.of("sku", sku, "operation", "find_orders_by_sku"));
        List<OrderEntity> orders = repo.findBySku(sku);
        ObservabilityHelper.logWithAttributes("orders found by sku", Map.of("sku", sku, "count", orders.size(), "operation", "orders_found_by_sku"));
        return orders;
    }

    @OtelSpan("OrderService.getOrderStats")
    public Map<String, Object> getOrderStats() {
        ObservabilityHelper.logWithAttributes("calculating order statistics", Map.of("operation", "calculate_order_stats"));
        
        List<OrderEntity> allOrders = repo.findAll();
        long totalOrders = allOrders.size();
        long uniqueSkus = allOrders.stream().map(OrderEntity::getSku).distinct().count();
        int totalQuantity = allOrders.stream().mapToInt(OrderEntity::getQuantity).sum();
        
        Map<String, Object> stats = Map.of(
            "total_orders", totalOrders,
            "unique_skus", uniqueSkus,
            "total_quantity", totalQuantity,
            "average_quantity_per_order", totalOrders > 0 ? (double) totalQuantity / totalOrders : 0.0
        );
        
        ObservabilityHelper.logWithAttributes("order statistics calculated", Map.of("total_orders", totalOrders, "unique_skus", uniqueSkus, "operation", "order_stats_calculated"));
        return stats;
    }

    @OtelSpan("OrderService.getMetrics")
    public Map<String, Object> getMetrics() {
        ObservabilityHelper.logWithAttributes("getting service metrics", Map.of("operation", "get_service_metrics"));
        
        List<OrderEntity> allOrders = repo.findAll();
        Map<String, Object> metrics = Map.of(
            "service_name", "orders-service",
            "version", "1.11.0",
            "total_orders", allOrders.size(),
            "uptime_seconds", System.currentTimeMillis() / 1000,
            "memory_usage_mb", Runtime.getRuntime().totalMemory() / 1024 / 1024,
            "free_memory_mb", Runtime.getRuntime().freeMemory() / 1024 / 1024
        );
        
        ObservabilityHelper.logWithAttributes("service metrics retrieved", Map.of("total_orders", allOrders.size(), "operation", "service_metrics_retrieved"));
        return metrics;
    }
}

