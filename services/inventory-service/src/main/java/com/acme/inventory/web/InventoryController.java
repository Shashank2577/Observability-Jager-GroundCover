package com.acme.inventory.web;

import com.acme.inventory.domain.InventoryItem;
import com.acme.inventory.service.InventoryService;
import com.acme.observability.annotation.OtelSpan;
import com.acme.observability.logging.ObservabilityHelper;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/inventory")
public class InventoryController {

    private final InventoryService service;

    public InventoryController(InventoryService service) { this.service = service; }

    @GetMapping
    @OtelSpan("InventoryController.list")
    public List<InventoryItem> list() { 
        ObservabilityHelper.logWithAttributes("listing inventory", Map.of("operation", "list_inventory"));
        return service.list(); 
    }

    @GetMapping("/{sku}")
    @OtelSpan("InventoryController.getBySku")
    public ResponseEntity<InventoryItem> getBySku(@PathVariable String sku) {
        ObservabilityHelper.logWithAttributes("getting inventory by sku", Map.of("sku", sku, "operation", "get_inventory_by_sku"));
        Optional<InventoryItem> item = service.findBySku(sku);
        return item.map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/reserve")
    @OtelSpan("InventoryController.reserve")
    public ResponseEntity<String> reserve(@RequestParam(name = "sku") String sku, @RequestParam(name = "qty") int qty) {
        ObservabilityHelper.logWithAttributes("reserve request", Map.of("sku", sku, "qty", qty, "operation", "reserve_inventory"));
        boolean ok = service.reserve(sku, qty);
        ObservabilityHelper.logWithAttributes("reserve attempt", Map.of("sku", sku, "qty", qty, "ok", ok, "operation", "reserve_attempt"));
        return ok ? ResponseEntity.ok("reserved") : ResponseEntity.status(409).body("insufficient");
    }

    @PostMapping("/add-stock")
    @OtelSpan("InventoryController.addStock")
    public ResponseEntity<String> addStock(@RequestParam(name = "sku") String sku, @RequestParam(name = "qty") int qty) {
        ObservabilityHelper.logWithAttributes("add stock request", Map.of("sku", sku, "qty", qty, "operation", "add_stock"));
        boolean ok = service.addStock(sku, qty);
        ObservabilityHelper.logWithAttributes("add stock result", Map.of("sku", sku, "qty", qty, "ok", ok, "operation", "add_stock_result"));
        return ok ? ResponseEntity.ok("stock added") : ResponseEntity.badRequest().body("failed to add stock");
    }

    @PostMapping("/batch-reserve")
    @OtelSpan("InventoryController.batchReserve")
    public ResponseEntity<Map<String, Object>> batchReserve(@RequestBody List<Map<String, Object>> reservations) {
        ObservabilityHelper.logWithAttributes("batch reserve request", Map.of("count", reservations.size(), "operation", "batch_reserve"));
        Map<String, Object> result = service.batchReserve(reservations);
        ObservabilityHelper.logWithAttributes("batch reserve completed", Map.of("successful", result.get("successful"), "failed", result.get("failed"), "operation", "batch_reserve_completed"));
        return ResponseEntity.ok(result);
    }

    @GetMapping("/stats")
    @OtelSpan("InventoryController.getStats")
    public Map<String, Object> getStats() {
        ObservabilityHelper.logWithAttributes("getting inventory statistics", Map.of("operation", "get_inventory_stats"));
        return service.getInventoryStats();
    }

    @GetMapping("/low-stock")
    @OtelSpan("InventoryController.getLowStock")
    public List<InventoryItem> getLowStock(@RequestParam(defaultValue = "10") int threshold) {
        ObservabilityHelper.logWithAttributes("getting low stock items", Map.of("threshold", threshold, "operation", "get_low_stock"));
        return service.getLowStockItems(threshold);
    }

    @GetMapping("/health")
    @OtelSpan("InventoryController.health")
    public Map<String, Object> health() { 
        ObservabilityHelper.logWithAttributes("health check", Map.of("operation", "health_check"));
        return Map.of("status", "OK", "service", "inventory-service", "version", "1.11.0");
    }

    @GetMapping("/metrics")
    @OtelSpan("InventoryController.metrics")
    public Map<String, Object> metrics() {
        ObservabilityHelper.logWithAttributes("getting metrics", Map.of("operation", "get_metrics"));
        return service.getMetrics();
    }
}
