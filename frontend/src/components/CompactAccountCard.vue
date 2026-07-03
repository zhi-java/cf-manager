<template>
  <n-popover trigger="click" :show="showPopover" @update:show="showPopover = $event" placement="bottom">
    <template #trigger>
      <div class="compact-card" @click="showPopover = !showPopover">
        <span class="compact-card__name" :title="accountName">{{ displayName }}</span>
        <span class="compact-card__dots">
          <n-tooltip
            v-for="(item, idx) in orderedResources"
            :key="item.resource.resource"
            trigger="hover"
          >
            <template #trigger>
              <span
                class="compact-card__dot"
                :style="{ backgroundColor: dotColor(item.resource) }"
              />
            </template>
            {{ item.label }}: {{ calcPercentage(item.resource) }}%
          </n-tooltip>
          <span
            v-for="n in emptyDots"
            :key="'empty-' + n"
            class="compact-card__dot"
            style="background-color: #ccc"
          />
        </span>
      </div>
    </template>
    <div class="compact-card__popover">
      <div class="compact-card__popover-title">{{ accountName }}</div>
      <div
        v-for="item in orderedResources"
        :key="item.resource.resource"
        class="compact-card__popover-row"
      >
        <div class="compact-card__popover-label">
          <span>{{ item.label }}</span>
          <span class="compact-card__popover-value">{{ formatValue(item.resource) }}</span>
        </div>
        <n-progress
          type="line"
          :percentage="calcPercentage(item.resource)"
          :height="14"
          :show-indicator="false"
          :status="progressStatus(item.resource)"
        />
      </div>
      <div v-if="orderedResources.length === 0" style="color: #999; font-size: 13px;">
        暂无资源数据
      </div>
    </div>
  </n-popover>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';

interface Resource {
  resource: string;
  count: number;
  limit: number;
}

const props = defineProps<{
  accountName: string;
  resources: Resource[];
}>();

const showPopover = ref(false);

const resourceOrder = ['workers_requests', 'ai_neurons', 'browser_render_seconds'];

const resourceLabels: Record<string, string> = {
  workers_requests: 'Workers 请求',
  ai_neurons: 'AI 神经元',
  browser_render_seconds: '浏览器渲染',
};

function resourceLabel(resource: string): string {
  return resourceLabels[resource] || resource;
}

function calcPercentage(r: Resource): number {
  if (!r.limit) return 0;
  return Math.min(100, Math.round(((r.count || 0) / r.limit) * 100));
}

function formatValue(r: Resource): string {
  if (r.resource === 'browser_render_seconds') {
    const m = Math.floor(r.count / 60);
    const s = Math.round(r.count % 60);
    const lm = Math.floor(r.limit / 60);
    const ls = Math.round(r.limit % 60);
    return `${m > 0 ? m + '分' : ''}${s}秒 / ${lm}分${ls > 0 ? ls + '秒' : ''}`;
  }
  return `${(r.count || 0).toLocaleString()} / ${(r.limit || 0).toLocaleString()}`;
}

function dotColor(r: Resource): string {
  const pct = calcPercentage(r);
  if (pct > 100) return '#c03030';
  if (pct > 90) return '#d03050';
  if (pct > 70) return '#f0a020';
  return '#18a058';
}

function progressStatus(r: Resource): 'error' | 'warning' | 'success' {
  const pct = calcPercentage(r);
  if (pct > 90) return 'error';
  if (pct > 70) return 'warning';
  return 'success';
}

const orderedResources = computed(() => {
  const map = new Map<string, Resource>();
  for (const r of props.resources) {
    map.set(r.resource, r);
  }
  return resourceOrder
    .filter((key) => map.has(key))
    .map((key) => ({
      resource: map.get(key)!,
      label: resourceLabel(key),
    }));
});

const emptyDots = computed(() => Math.max(0, 3 - orderedResources.value.length));

const displayName = computed(() => {
  if (props.accountName.length <= 8) return props.accountName;
  return props.accountName.slice(0, 8) + '...';
});
</script>

<style scoped>
.compact-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 120px;
  height: 28px;
  padding: 4px;
  border-radius: 4px;
  cursor: pointer;
  background-color: rgba(0, 0, 0, 0.03);
  transition: background-color 0.2s;
}

.compact-card:hover {
  background-color: rgba(0, 0, 0, 0.08);
}

.compact-card__name {
  font-size: 12px;
  max-width: 70px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.compact-card__dots {
  display: flex;
  gap: 3px;
  align-items: center;
}

.compact-card__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.compact-card__popover {
  width: 300px;
}

.compact-card__popover-title {
  font-weight: bold;
  margin-bottom: 12px;
}

.compact-card__popover-row {
  margin-bottom: 12px;
}

.compact-card__popover-row:last-child {
  margin-bottom: 0;
}

.compact-card__popover-label {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  margin-bottom: 4px;
}

.compact-card__popover-value {
  color: #999;
}
</style>
