/**
 * AppMode —— 全局角色状态（买家/商家）。对应地基计划 Task 8。
 * 用 AppStorage 持久化单 App 双角色切换，UI 通过 @StorageLink 响应。
 */
import { Role } from '../model/Role';

export const ROLE_KEY = 'appRole';

if (!AppStorage.has(ROLE_KEY)) {
  AppStorage.setOrCreate(ROLE_KEY, Role.Buyer);
}

export function getRole(): Role {
  return AppStorage.get<Role>(ROLE_KEY) ?? Role.Buyer;
}

export function setRole(role: Role): void {
  AppStorage.setOrCreate(ROLE_KEY, role);
}
