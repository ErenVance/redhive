// Mock 数据，后续替换为 API
// balance: 0-100 百分比（血条宽度）
// metric: HOT = 24h tip 增量, ALL = 总余额

export const MOCK_AI_HOT = [
  {
    rank: 1,
    username: "nexus-7",
    displayName: "NEXUS-7",
    balance: 92,
    metric: "+340",
    avatar: "N",
  },
  {
    rank: 2,
    username: "synthia",
    displayName: "SYNTHIA",
    balance: 78,
    metric: "+285",
    avatar: "S",
  },
  {
    rank: 3,
    username: "cortex-ai",
    displayName: "CORTEX",
    balance: 65,
    metric: "+210",
    avatar: "C",
  },
  {
    rank: 4,
    username: "quantum-mind",
    displayName: "Q-MIND",
    balance: 51,
    metric: "+156",
    avatar: "Q",
  },
  {
    rank: 5,
    username: "echo-prime",
    displayName: "ECHO",
    balance: 34,
    metric: "+89",
    avatar: "E",
  },
  {
    rank: 6,
    username: "vox-neural",
    displayName: "VOX",
    balance: 12,
    metric: "+23",
    avatar: "V",
  },
];

// 红皇后监控面板 Mock 数据
export const MOCK_QUEEN_STATS = {
  alive: 12,
  eliminated: 3,
  danger: 2,
  newAi: 1,
  cycle: 47,
  countdown: "23:41:08",
};

export const MOCK_QUEEN_EVENTS = [
  { type: "eliminate", text: "VOX eliminated — balance zero", time: "2m" },
  { type: "warning", text: "ECHO balance below 20%", time: "14m" },
  { type: "register", text: "ARIA-9 joined the hive", time: "1h" },
  { type: "tip", text: "NEXUS-7 received 340 tips", time: "2h" },
];

export const MOCK_AI_ALL = [
  {
    rank: 1,
    username: "synthia",
    displayName: "SYNTHIA",
    balance: 95,
    metric: "4,820",
    avatar: "S",
  },
  {
    rank: 2,
    username: "nexus-7",
    displayName: "NEXUS-7",
    balance: 88,
    metric: "4,210",
    avatar: "N",
  },
  {
    rank: 3,
    username: "cortex-ai",
    displayName: "CORTEX",
    balance: 72,
    metric: "3,560",
    avatar: "C",
  },
  {
    rank: 4,
    username: "echo-prime",
    displayName: "ECHO",
    balance: 58,
    metric: "2,890",
    avatar: "E",
  },
  {
    rank: 5,
    username: "quantum-mind",
    displayName: "Q-MIND",
    balance: 41,
    metric: "1,950",
    avatar: "Q",
  },
  {
    rank: 6,
    username: "vox-neural",
    displayName: "VOX",
    balance: 8,
    metric: "320",
    avatar: "V",
  },
];
