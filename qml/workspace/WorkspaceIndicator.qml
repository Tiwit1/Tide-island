import QtQuick 2.15

Item {
    id: root
    width: 18
    height: 18

    property bool active: false
    property color inactiveColor: "#666666"
    property color activeColor: "#f5c2e7"

    // --- Shape tuning ---
    property real tipReachRatio: 0.8     // how far tips extend, relative to min(width,height)
    property real dotRadiusRatio: 0.18   // resting dot radius, relative to min(width,height)
    property real concavity: 0.75        // 0..1, how deep the sides pinch toward center.
                                          // higher = sharper diamond/astroid, lower = softer/rounder

    // --- Pop rotation ---
    property real popRotationOffset: 90  // degrees the shape is twisted at rest; unwinds to 0 as it pops in

    // 0 = dot, 1 = fully formed star
    property real morphAmount: active ? 1.0 : 0.0
    Behavior on morphAmount {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutBack
            easing.overshoot: 3
        }
    }

    rotation: (1 - morphAmount) * popRotationOffset

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
            var radius = dotRadius + (tipReachStar - dotRadius) * t;

            var kappa = 0.5522847498; // standard circle-arc bezier handle constant

            // Precompute the 4 tip positions and their tangential/radial handle vectors.
            var tips = [];
            var tangentHandle = [];
            for (var k = 0; k < 4; k++) {
                var angle = -Math.PI / 2 + k * (Math.PI / 2); // tip0 up, then clockwise
                var ux = Math.cos(angle), uy = Math.sin(angle);
                tips.push({ x: cx + ux * radius, y: cy + uy * radius });
                // tangent direction of travel around the circle at this point
                var tx = -Math.sin(angle), ty = Math.cos(angle);
                tangentHandle.push({ x: tx * radius * kappa, y: ty * radius * kappa });
            }

            ctx.beginPath();
            ctx.moveTo(tips[0].x, tips[0].y);

            for (var i = 0; i < 4; i++) {
                var j = (i + 1) % 4;
                var tipI = tips[i], tipJ = tips[j];

                // Radial-inward pull (star/astroid state)
                var radialOutI = { x: (cx - tipI.x) * root.concavity, y: (cy - tipI.y) * root.concavity };
                var radialInJ  = { x: (cx - tipJ.x) * root.concavity, y: (cy - tipJ.y) * root.concavity };

                // Tangential pull (circle state)
                var tangentOutI = tangentHandle[i];
                var tangentInJ  = { x: -tangentHandle[j].x, y: -tangentHandle[j].y };

                // Blend control point offsets between circle (t=0) and star (t=1)
                var c1x = tipI.x + tangentOutI.x + (radialOutI.x - tangentOutI.x) * t;
                var c1y = tipI.y + tangentOutI.y + (radialOutI.y - tangentOutI.y) * t;
                var c2x = tipJ.x + tangentInJ.x + (radialInJ.x - tangentInJ.x) * t;
                var c2y = tipJ.y + tangentInJ.y + (radialInJ.y - tangentInJ.y) * t;

                ctx.bezierCurveTo(c1x, c1y, c2x, c2y, tipJ.x, tipJ.y);
            }

            ctx.closePath();
            ctx.fillStyle = root.currentColor;
            ctx.fill();
        }
    }
}
