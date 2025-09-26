package com.acme.orders.web;

import com.acme.observability.annotation.OtelSpan;
import com.acme.observability.logging.ObservabilityHelper;
import com.acme.orders.domain.OrderEntity;
import com.acme.orders.service.OrderService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/orders")
public class OrdersController {

    private final OrderService service;

    public OrdersController(OrderService service) { this.service = service; }

    @PostMapping
    @OtelSpan("OrdersController.create")
    public ResponseEntity<OrderEntity> create(@RequestParam(name = "sku") String sku, @RequestParam(name = "qty") int qty) {
        ObservabilityHelper.logWithAttributes("creating order", Map.of("sku", sku, "qty", qty));
        return ResponseEntity.ok(service.place(sku, qty));
    }

    @GetMapping
    @OtelSpan
    public List<OrderEntity> list() { return service.list(); }

    @GetMapping("/health")
    public String health() { return "OK"; }
}
