import QtQuick 2.15

// A single workspace indicator that morphs between a plain dot
// and a 4-point sparkle/astroid star (pointy tips, concave sides pinching
// in toward the center) when active.
//
// Usage:
//   WorkspaceIndicator {
//       active: index === activeWorkspaceIndex
//   }

Item {
    id: root
    width: 18
    height: 18

    property bool active: false
    property color inactiveColor: '#ffffff'
    property color activeColor: '#ffffff'

    // --- Shape tuning (star state) ---
    property real tipReachRatio: 1    // how far tips extend, relative to min(width,height)
    property real concavity: 0.85        // 0..1, how deep the sides pinch toward center.
                                          // higher = sharper diamond/astroid, lower = softer/rounder

    // --- Resting dot state ---
    property real dotRadiusRatio: 0.25    // relative to min(width,height)

    // 0 = dot, 1 = fully formed star
    property real morphAmount: active ? 1.0 : 0.0
    Behavior on morphAmount {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutBack
            easing.overshoot: 3
        }
    }

    property color currentColor: Qt.rgba(
        inactiveColor.r + (activeColor.r - inactiveColor.r) * morphAmount,
        inactiveColor.g + (activeColor.g - inactiveColor.g) * morphAmount,
        inactiveColor.b + (activeColor.b - inactiveColor.b) * morphAmount,
        1.0
    )

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        Connections {
            target: root
            function onMorphAmountChanged() { canvas.requestPaint() }
            function onCurrentColorChanged() { canvas.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var cx = width / 2;
            var cy = height / 2;
            var minDim = Math.min(width, height);
            var t = root.morphAmount;

            var dotRadius = minDim * root.dotRadiusRatio;
            var tipReachStar = minDim * root.tipReachRatio;
            // Size is allowed to overshoot with the spring (raw t), which is what
            // gives the pop its punch. The shape BLEND is clamped to 0..1 —
            // letting it extrapolate past "pure star" during the overshoot would
            // over-pull the control points past the center and self-intersect,
            // which is what caused the flicker.
            var radius = dotRadius + (tipReachStar - dotRadius) * t;
            var shapeT = Math.max(0, Math.min(1, t));

            var kappa = 0.5522847498; // standard circle-arc bezier handle constant

            // Precompute the 4 tip positions and their tangential handle vectors
            // (used for the resting circle state).
            var tips = [];
            var tangentHandle = [];
            for (var k = 0; k < 4; k++) {
                var angle = -Math.PI / 2 + k * (Math.PI / 2); // tip0 up, then clockwise
                var ux = Math.cos(angle), uy = Math.sin(angle);
                tips.push({ x: cx + ux * radius, y: cy + uy * radius });
                var tx = -Math.sin(angle), ty = Math.cos(angle);
                tangentHandle.push({ x: tx * radius * kappa, y: ty * radius * kappa });
            }

            ctx.beginPath();
            ctx.moveTo(tips[0].x, tips[0].y);

            for (var i = 0; i < 4; i++) {
                var j = (i + 1) % 4;
                var tipI = tips[i], tipJ = tips[j];

                // Radial-inward pull (star/astroid state) — this is what makes
                // the sides concave instead of bulging outward.
                var radialOutI = { x: (cx - tipI.x) * root.concavity, y: (cy - tipI.y) * root.concavity };
                var radialInJ  = { x: (cx - tipJ.x) * root.concavity, y: (cy - tipJ.y) * root.concavity };

                // Tangential pull (circle state)
                var tangentOutI = tangentHandle[i];
                var tangentInJ  = { x: -tangentHandle[j].x, y: -tangentHandle[j].y };

                // Blend control point offsets between circle (shapeT=0) and star (shapeT=1)
                var c1x = tipI.x + tangentOutI.x + (radialOutI.x - tangentOutI.x) * shapeT;
                var c1y = tipI.y + tangentOutI.y + (radialOutI.y - tangentOutI.y) * shapeT;
                var c2x = tipJ.x + tangentInJ.x + (radialInJ.x - tangentInJ.x) * shapeT;
                var c2y = tipJ.y + tangentInJ.y + (radialInJ.y - tangentInJ.y) * shapeT;

                ctx.bezierCurveTo(c1x, c1y, c2x, c2y, tipJ.x, tipJ.y);
            }

            ctx.closePath();
            ctx.fillStyle = root.currentColor;
            ctx.fill();
        }
    }
}
