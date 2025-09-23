extends Node

# O sinal abaixo é exposto para futuras integrações (HUD, contagem de moedas).
# No momento não é referenciado diretamente, então ignoramos o aviso do linter.
@warning_ignore("unused_signal")
signal coin_collected(value: int)
