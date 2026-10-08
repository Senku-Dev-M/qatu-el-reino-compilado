class_name PipelineQuiz
extends RefCounted
## Desafío interactivo de pipelines y Kubernetes para la fase 3 de Kubernetes, el Timonel.
## El jugador debe activar las directivas y comandos correctos para estabilizar el clúster.

const QUESTIONS := [
	{
		"prompt": "Construir, publicar y desplegar el microservicio de Qatu en el clúster",
		"correct": ["docker build", "docker push", "kubectl apply"],
		"options": ["docker build", "docker push", "kubectl apply", "docker rm", "npm start", "git drop"]
	},
	{
		"prompt": "Definir servicio multicontenedor reproducible con puertos mapeados",
		"correct": ["docker-compose.yml", "services", "ports"],
		"options": ["docker-compose.yml", "services", "ports", "k8s-pod.exe", "Makefile", "sudo apt"]
	},
	{
		"prompt": "Exponer el Deployment de producción al tráfico externo balanceado",
		"correct": ["Service", "LoadBalancer", "Ingress"],
		"options": ["Service", "LoadBalancer", "Ingress", "HostPath", "ClusterIP-Only", "kill -9"]
	}
]

var current_idx := 0
var selected: Array[String] = []

func current_question() -> Dictionary:
	return QUESTIONS[current_idx % QUESTIONS.size()]

func submit_choice(choice: String) -> bool:
	var q := current_question()
	var needed: Array = q.correct
	if choice in needed and not (choice in selected):
		selected.append(choice)
		if selected.size() == needed.size():
			current_idx += 1
			selected.clear()
			return true
	return false

func is_complete() -> bool:
	return current_idx >= QUESTIONS.size()
