module.exports =
  getSpyByIdentity: (identity) ->
    for spy in jasmine.getEnv().currentSpec.spies_
      if spy.identity == identity
        return spy
    null
