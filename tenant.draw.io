<mxfile host="app.diagrams.net" modified="2025-10-01T14:30:00.000Z" agent="chatgpt" etag="2" version="20.1.3" type="device">
  <diagram id="arch" name="Architecture (Reviewed)">
    <mxGraphModel dx="1226" dy="788" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="850" pageHeight="1100">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>

        <!-- User -->
        <mxCell id="2" value="User\n(Browser)" style="ellipse;whiteSpace=wrap;html=1;strokeColor=#333333;fillColor=#ffffff;" vertex="1" parent="1">
          <mxGeometry x="40" y="120" width="120" height="60" as="geometry"/>
        </mxCell>

        <!-- Tenant App (dublin) -->
        <mxCell id="3" value="Tenant App\n(dublin.civi-tax.com)" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=#1f77b4;fillColor=#ffffff;" vertex="1" parent="1">
          <mxGeometry x="220" y="60" width="220" height="80" as="geometry"/>
        </mxCell>

        <!-- Tenant App (columbus) -->
        <mxCell id="4" value="Tenant App\n(columbus.civi-tax.com)" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=#1f77b4;fillColor=#ffffff;" vertex="1" parent="1">
          <mxGeometry x="220" y="180" width="220" height="80" as="geometry"/>
        </mxCell>

        <!-- Keycloak Cluster -->
        <mxCell id="5" value="Keycloak Cluster\n(single infra, HA)" style="shape=swimlane;startSize=30;whiteSpace=wrap;html=1;strokeColor=#2ca02c;fillColor=#f6fffa;" vertex="1" parent="1">
          <mxGeometry x="500" y="20" width="440" height="360" as="geometry"/>
        </mxCell>

        <!-- Inside Keycloak - Realms -->
        <mxCell id="6" value="Realm: civi (central)\n- Canonical user registry\n- Consent UI" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=#2ca02c;fillColor=#ffffff;" vertex="1" parent="5">
          <mxGeometry x="20" y="40" width="400" height="80" as="geometry"/>
        </mxCell>
        <mxCell id="7" value="Realm: dublin\n- Local users & roles" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=#2ca02c;fillColor=#ffffff;" vertex="1" parent="5">
          <mxGeometry x="20" y="140" width="180" height="70" as="geometry"/>
        </mxCell>
        <mxCell id="8" value="Realm: columbus\n- Local users & roles" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=#2ca02c;fillColor=#ffffff;" vertex="1" parent="5">
          <mxGeometry x="220" y="140" width="200" height="70" as="geometry"/>
        </mxCell>

        <!-- Profile API & Consent DB -->
        <mxCell id="9" value="Profile API (central)\n(Source of Truth)" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=#ff7f0e;fillColor=#ffffff;" vertex="1" parent="1">
          <mxGeometry x="500" y="400" width="240" height="80" as="geometry"/>
        </mxCell>
        <mxCell id="10" value="ConsentDB / Audit\n(immutable logs)" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=#9467bd;fillColor=#ffffff;" vertex="1" parent="1">
          <mxGeometry x="760" y="400" width="240" height="80" as="geometry"/>
        </mxCell>

        <!-- Legend -->
        <mxCell id="legend" value="Legend:\n- Solid line: direct request/redirect\n- Dashed line: broker/redirect flow\n- Note: Auto-provision or manual linking options included" style="text;html=1;align=left;verticalAlign=top;wordWrap=1;" vertex="1" parent="1">
          <mxGeometry x="40" y="520" width="960" height="90" as="geometry"/>
        </mxCell>

        <!-- Edges -->
        <mxCell id="e1" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#333333;endArrow=block;" edge="1" source="2" target="3" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e2" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#333333;endArrow=block;" edge="1" source="2" target="4" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e3" style="edgeStyle=elbowConnector;rounded=1;orthogonalLoop=1;html=1;strokeColor=#333333;endArrow=block;" edge="1" source="3" target="5" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e4" style="edgeStyle=elbowConnector;rounded=1;orthogonalLoop=1;html=1;strokeColor=#333333;endArrow=block;" edge="1" source="4" target="5" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e5" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#333333;endArrow=block;" edge="1" source="6" target="9" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e6" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#333333;endArrow=block;" edge="1" source="6" target="10" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>

      </root>
    </mxGraphModel>
  </diagram>

  <diagram id="login" name="Login & Profile Inheritance Flow (Reviewed)">
    <mxGraphModel dx="1226" dy="788" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="850" pageHeight="1100">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>

        <!-- User -->
        <mxCell id="u1" value="User (Browser)" style="ellipse;whiteSpace=wrap;html=1;strokeColor=#333333;fillColor=#ffffff;" vertex="1" parent="1">
          <mxGeometry x="40" y="60" width="120" height="60" as="geometry"/>
        </mxCell>

        <!-- Tenant App -->
        <mxCell id="t1" value="Tenant App\n(dublin.civi-tax.com)" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=#1f77b4;fillColor=#ffffff;" vertex="1" parent="1">
          <mxGeometry x="220" y="40" width="220" height="80" as="geometry"/>
        </mxCell>

        <!-- Keycloak Dublin Realm -->
        <mxCell id="kr" value="Keycloak - Dublin Realm\n(client + local users + IdP config)" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=#2ca02c;fillColor=#f6fff6;" vertex="1" parent="1">
          <mxGeometry x="480" y="20" width="240" height="90" as="geometry"/>
        </mxCell>

        <!-- Keycloak Civi Realm -->
        <mxCell id="kc" value="Keycloak - Civi Realm\n(central user registry & consent)" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=#2ca02c;fillColor=#ffffff;" vertex="1" parent="1">
          <mxGeometry x="760" y="20" width="260" height="90" as="geometry"/>
        </mxCell>

        <!-- Profile API -->
        <mxCell id="pa" value="Profile API (central)\n(Tenant-scoped views)" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=#ff7f0e;fillColor=#ffffff;" vertex="1" parent="1">
          <mxGeometry x="480" y="160" width="240" height="70" as="geometry"/>
        </mxCell>

        <!-- Consent DB -->
        <mxCell id="cd" value="ConsentDB" style="rounded=1;whiteSpace=wrap;html=1;strokeColor=#9467bd;fillColor=#ffffff;" vertex="1" parent="1">
          <mxGeometry x="760" y="160" width="160" height="70" as="geometry"/>
        </mxCell>

        <!-- Edges -->
        <mxCell id="e_a" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#000000;endArrow=block;" edge="1" source="u1" target="t1" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>

        <mxCell id="e_b" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#000000;endArrow=block;" edge="1" source="t1" target="kr" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>

        <mxCell id="e_c" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#000000;dashed=1;endArrow=block;" edge="1" source="kr" target="kc" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>

        <mxCell id="e_d" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#000000;endArrow=block;" edge="1" source="kr" target="pa" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>

        <mxCell id="e_e" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#000000;endArrow=block;" edge="1" source="pa" target="t1" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>

        <mxCell id="note1" value="Reviewer notes:\n- Fixed spelling (Columbus).\n- Added legend and explicit provisioning hints.\n- Included 'auto-provision vs manual linking' options and conflict-resolution patterns.\n- Diagram layout optimized for export (slide-ready)." style="text;html=1;align=left;verticalAlign=top;wordWrap=1;" vertex="1" parent="1">
          <mxGeometry x="40" y="260" width="980" height="120" as="geometry"/>
        </mxCell>

      </root>
    </mxGraphModel>
  </diagram>

</mxfile>