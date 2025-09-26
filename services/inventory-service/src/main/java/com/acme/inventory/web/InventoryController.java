package com.acme.inventory.web;

import com.acme.inventory.domain.InventoryItem;
import com.acme.inventory.service.InventoryService;
import com.acme.observability.annotation.OtelSpan;
import com.acme.observability.logging.ObservabilityHelper;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/inventory")
public class InventoryController {

    private final InventoryService service;

    public InventoryController(InventoryService service) { this.service = service; }

    @GetMapping
    @OtelSpan
    public List<InventoryItem> list() { return service.list(); }

    @PostMapping("/reserve")
    @OtelSpan("InventoryController.reserve")
    public ResponseEntity<String> reserve(@RequestParam(name = "sku") String sku, @RequestParam(name = "qty") int qty) {
        boolean ok = service.reserve(sku, qty);
        ObservabilityHelper.logWithAttributes("reserve attempt", Map.of("sku", sku, "qty", qty, "ok", ok));
        return ok ? ResponseEntity.ok("reserved") : ResponseEntity.status(409).body("insufficient");
    }

    @PostMapping("/add-stock")
    @OtelSpan("InventoryController.addStock")
    public ResponseEntity<String> addStock(@RequestParam(name = "sku") String sku, @RequestParam(name = "qty") int qty) {
        boolean ok = service.addStock(sku, qty);
        return ok ? ResponseEntity.ok("stock added") : ResponseEntity.badRequest().body("failed to add stock");
    }

    @GetMapping("/health")
    public String health() { return "OK"; }
}
