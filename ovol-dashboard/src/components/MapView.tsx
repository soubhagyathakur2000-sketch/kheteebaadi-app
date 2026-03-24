'use client';

import { useEffect, useRef, useState } from 'react';
import mapboxgl, { GeoJSONSource, GeoJSONSourceRaw } from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { useMapStore, useFilterStore } from '@/lib/store';
import { Village } from '@/lib/types';

interface MapViewProps {
  villages: Village[];
  onVillageClick?: (village: Village) => void;
  loading?: boolean;
}

export default function MapView({ villages, onVillageClick, loading }: MapViewProps) {
  const mapContainer = useRef<HTMLDivElement>(null);
  const map = useRef<mapboxgl.Map | null>(null);
  const { viewport, setViewport } = useMapStore();
  const { stockLevel } = useFilterStore();
  const [mapLoaded, setMapLoaded] = useState(false);

  const token = process.env.NEXT_PUBLIC_MAPBOX_TOKEN;

  useEffect(() => {
    if (!token) {
      console.error('Mapbox token not configured');
      return;
    }

    if (!mapContainer.current) return;

    mapboxgl.accessToken = token;

    map.current = new mapboxgl.Map({
      container: mapContainer.current,
      style: 'mapbox://styles/mapbox/light-v11',
      center: [viewport.lng, viewport.lat],
      zoom: viewport.zoom,
    });

    map.current.on('load', () => {
      setMapLoaded(true);

      // Add cluster layer
      if (map.current) {
        map.current.addSource('villages', {
          type: 'geojson',
          data: {
            type: 'FeatureCollection',
            features: [],
          },
          cluster: true,
          clusterMaxZoom: 12,
          clusterRadius: 50,
        });

        map.current.addLayer({
          id: 'clusters',
          type: 'circle',
          source: 'villages',
          filter: ['has', 'point_count'],
          paint: {
            'circle-color': '#2E7D32',
            'circle-radius': ['step', ['get', 'point_count'], 20, 100, 30, 750, 40],
          },
        });

        map.current.addLayer({
          id: 'cluster-count',
          type: 'symbol',
          source: 'villages',
          filter: ['has', 'point_count'],
          layout: {
            'text-field': ['get', 'point_count'],
            'text-font': ['Open Sans Semibold'],
            'text-size': 12,
            'text-offset': [0, 0],
          },
          paint: {
            'text-color': '#ffffff',
          },
        });

        map.current.addLayer({
          id: 'unclustered-point',
          type: 'circle',
          source: 'villages',
          filter: ['!', ['has', 'point_count']],
          paint: {
            'circle-color': [
              'step',
              ['get', 'stockHealthPercent'],
              '#E53935',
              33,
              '#FFA726',
              66,
              '#43A047',
            ],
            'circle-radius': 8,
            'circle-stroke-width': 2,
            'circle-stroke-color': '#fff',
          },
        });
      }
    });

    map.current.on('move', () => {
      if (map.current) {
        const center = map.current.getCenter();
        setViewport({
          lat: center.lat,
          lng: center.lng,
          zoom: map.current.getZoom(),
        });
      }
    });

    map.current.on('click', 'unclustered-point', (e) => {
      if (e.features && e.features[0]) {
        const feature = e.features[0];
        const village = villages.find((v) => v.id === feature.properties?.id);
        if (village && onVillageClick) {
          onVillageClick(village);
        }

        const coordinates = feature.geometry.type === 'Point' ? feature.geometry.coordinates : [0, 0];
        new mapboxgl.Popup()
          .setLngLat([coordinates[0] as number, coordinates[1] as number])
          .setHTML(`
            <div class="p-4">
              <h3 class="font-bold text-gray-900">${village?.name || 'Village'}</h3>
              <p class="text-sm text-gray-600 mt-1">
                Farmers: ${village?.farmerCount || 0}
              </p>
              <p class="text-sm text-gray-600">
                Stock Level: ${village?.totalStock || 0} units
              </p>
              <p class="text-sm text-gray-600">
                Health: ${village?.avgStockHealth || 0}%
              </p>
            </div>
          `)
          .addTo(map.current!);
      }
    });

    map.current.on('mouseenter', 'unclustered-point', () => {
      if (map.current) {
        map.current.getCanvas().style.cursor = 'pointer';
      }
    });

    map.current.on('mouseleave', 'unclustered-point', () => {
      if (map.current) {
        map.current.getCanvas().style.cursor = '';
      }
    });

    return () => {
      map.current?.remove();
    };
  }, [token]);

  // Update data when villages change
  useEffect(() => {
    if (mapLoaded && map.current && villages.length > 0) {
      const source = map.current.getSource('villages') as GeoJSONSource;

      const filteredVillages = villages.filter((v) => {
        if (stockLevel === 'high') return v.avgStockHealth >= 66;
        if (stockLevel === 'medium') return v.avgStockHealth >= 33 && v.avgStockHealth < 66;
        if (stockLevel === 'low') return v.avgStockHealth < 33;
        return true;
      });

      const geojson: GeoJSONSourceRaw = {
        type: 'FeatureCollection',
        features: filteredVillages.map((v) => ({
          type: 'Feature' as const,
          geometry: {
            type: 'Point' as const,
            coordinates: [v.longitude, v.latitude],
          },
          properties: {
            id: v.id,
            name: v.name,
            farmerCount: v.farmerCount,
            totalStock: v.totalStock,
            avgStockHealth: v.avgStockHealth,
            stockHealthPercent: v.avgStockHealth,
          },
        })),
      };

      source.setData(geojson);
    }
  }, [villages, mapLoaded, stockLevel]);

  return (
    <div
      ref={mapContainer}
      className="h-full w-full"
      style={{ minHeight: '100vh' }}
    />
  );
}
