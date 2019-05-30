"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.contractTests = (testName, config) => {
    describe(testName, () => {
        let frameworkAdapter;
        beforeAll(config.before);
        afterAll(config.after);
        beforeEach(async () => {
            frameworkAdapter = config.adapterSetup();
        });
        it('Should have tests here', () => {
            expect(frameworkAdapter.info).toHaveProperty('server');
            expect(frameworkAdapter).toHaveProperty('server');
        });
    });
};
