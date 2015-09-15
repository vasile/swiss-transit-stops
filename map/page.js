$(document).ready(function() {
    var ua_is_mobile = navigator.userAgent.indexOf('iPhone') !== -1 || navigator.userAgent.indexOf('Android') !== -1;
    if (ua_is_mobile) {
        $('body').addClass('mobile');
    }
    
    var layers = [];

    var layer = ga.layer.create('ch.swisstopo.pixelkarte-farbe');
    layer.setOpacity(0.5);
    layers.push(layer);

    var style_cache = {};

    var type_map_style = {
        boat: {
            color: '#0000FF',
            zIndex: '10'
        },
        bus: {
            color: '#800080',
            zIndex: '40'
        },
        cable: {
            color: '#FF8C00',
            zIndex: '20'
        },
        train: {
            color: '#FF0000',
            zIndex: '50'
        },
        tram: {
            color: '#008000',
            zIndex: '30'
        }
    };

    var map_legend_parts = [];
    for (var stop_type in type_map_style) {
        var map_legend_part = '<span class="label" style="background-color: ' + type_map_style[stop_type].color + '">' + stop_type + '</span> <span id="legend_stop_type_' + stop_type + '"></span>';
        map_legend_parts.push(map_legend_part);
    }
    $('#map_legend').html(map_legend_parts.join(' '));

    var geojson_layer = new ol.layer.Vector({
        source: new ol.source.Vector({
            projection: 'EPSG:21781',
            url: 'stops.geojson',
            format: new ol.format.GeoJSON()
        }),
        style: function(feature, resolution) {
            var f_type = feature.get('stop_main_type');
            var cache_key = 'cache_' + resolution + '_' + f_type;
            if ((typeof style_cache[cache_key]) === 'undefined') {
                var styles = [];
                var style_dot = new ol.style.Style({
                    image: new ol.style.Circle({
                        radius: resolution < 50 ? 5 : 3,
                        fill: new ol.style.Fill({
                            color: type_map_style[f_type].color
                        }),
                        stroke: new ol.style.Stroke({
                            color: '#CACACA',
                            width: 1
                        })
                    }),
                    zIndex: type_map_style[f_type].zIndex
                });

                styles.push(style_dot);

                style_cache[cache_key] = styles;
            }

            return style_cache[cache_key];
        }
    });
    layers.push(geojson_layer);

    geojson_layer.on('change', function(){
        geojson_layer.getSource().forEachFeature(function(feature){
            $.each(feature.get('stop_types').split(','), function(k, stop_type){
                if ((typeof type_map_style[stop_type].count) === 'undefined') {
                    type_map_style[stop_type].count = 0;
                }
                type_map_style[stop_type].count += 1;
            });
        });

        for (var stop_type in type_map_style) {
            $('#legend_stop_type_' + stop_type).html(type_map_style[stop_type].count);
        }
    });

    var area_info = new ol.Overlay({
        element: $('#map_area_info')[0]
    });

    var map = new ga.Map({
        target: 'map_canvas',
        layers: layers,
        view: new ol.View2D({
            resolution: 20,
            center: ol.proj.transform([8.546, 47.383], 'EPSG:4326', 'EPSG:21781')
        }),
        overlays: [area_info]
    });

    map.getView().on('change:resolution', function(){
        console.log('zoom is ' + map.getView().getResolution());
    });

    map.getView().on('change:center', function(){
        console.log('center is ' + ol.proj.transform(map.getView().getCenter(), 'EPSG:21781', 'EPSG:4326'));
    });

    map.on('singleclick', function(ev) {
        var pixel = map.getEventPixel(ev.originalEvent);
        var selected_feature = null;
        map.forEachFeatureAtPixel(pixel, function(feature, layer) {
            selected_feature = feature;
        });

        if (selected_feature === null) {
            return;
        }

        var stop_type_parts = [];
        $.each(selected_feature.get('stop_types').split(','), function(k, stop_type){
            var stop_type_part = '<span class="label" style="background-color: ' + type_map_style[stop_type].color + '">' + stop_type + '</span>';
            stop_type_parts.push(stop_type_part);
        });

        area_info.setPosition(ev.coordinate);
        var popup_content = '<div><b>' + selected_feature.get('stop_name') + '</b><br/>' + stop_type_parts.join('') + '</div>';
        $('#map_area_info .ol-popup-content').html(popup_content);
        $('#map_area_info').removeClass('hide');
    });

    $('#map_area_info .ol-popup-closer').click(function() {
        $('#map_area_info').addClass('hide');
        return false;
    });
});