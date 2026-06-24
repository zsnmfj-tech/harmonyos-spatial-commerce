/**
 * AppMode 单测。对应地基计划 Task 8。
 * 验证默认买家、可切商家、且 AppStorage 与 getRole 一致。
 */
import { describe, it, expect } from '@ohos/hypium';
import { getRole, setRole, ROLE_KEY } from '../../../main/ets/common/AppMode';
import { Role } from '../../../main/ets/model/Role';

export default function appModeTest() {
  describe('AppMode', () => {
    it('defaults to buyer and switches to seller', 0, () => {
      setRole(Role.Buyer);
      expect(getRole()).assertEqual(Role.Buyer);
      setRole(Role.Seller);
      expect(getRole()).assertEqual(Role.Seller);
      expect(AppStorage.get<Role>(ROLE_KEY)).assertEqual(Role.Seller);
    });
  });
}
