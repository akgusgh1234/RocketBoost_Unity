using UnityEngine;
using UnityEngine.InputSystem;

public class Movement : MonoBehaviour
{
    [SerializeField] InputAction thrust;
    [SerializeField] InputAction rotation;
    [SerializeField] float thrustStrength = 1000f;
    [SerializeField] float rotationStrength = 100f;
    [SerializeField] float rotationDamping = 2f; // 회전 관성 감쇠(마찰) 값
    [SerializeField] AudioClip mainEngine;
    [SerializeField] ParticleSystem MainboosterParticles;
    [SerializeField] ParticleSystem LeftboosterParticles;
    [SerializeField] ParticleSystem RightboosterParticles;

    Rigidbody rb;
    AudioSource audioSource;

    void Start()
    {
        rb = GetComponent<Rigidbody>();
        audioSource = GetComponent<AudioSource>();
    }

    void OnEnable()
    {
        thrust.Enable();
        rotation.Enable();
    }

    void FixedUpdate()
    {
        ProcessThrust();
        ProcessRotation();
    }

    private void ProcessThrust()
    {
        if (thrust.IsPressed())
        {
            startThrusting();
        }
        else
        {
            StopThrusing();
        }
    }
    private void startThrusting()
    {
        rb.AddRelativeForce(Vector3.up * thrustStrength * Time.fixedDeltaTime);

        if (!audioSource.isPlaying)
            audioSource.PlayOneShot(mainEngine);
        if (!MainboosterParticles.isPlaying)
            MainboosterParticles.Play();
    }
    private void StopThrusing()
    {
        audioSource.Stop();
        MainboosterParticles.Stop();
    }



    private void ProcessRotation()
    {
        float rotationInput = rotation.ReadValue<float>();

        if (Mathf.Abs(rotationInput) > 0.01f)
        {
            // 입력이 있을 때는 각속도 추가
            StartRotate(rotationInput);
        }
        else
        {
            // 입력이 없으면 서서히 감속 (마찰처럼)
            StopRotate();
        }
    }

    private void StartRotate(float rotationInput)
    {
        rb.AddTorque(Vector3.forward * -rotationInput * rotationStrength * Time.fixedDeltaTime, ForceMode.Acceleration);
        if (!RightboosterParticles.isPlaying && rotationInput < 0)
            RightboosterParticles.Play();
        else if (!LeftboosterParticles.isPlaying && rotationInput > 0)
            LeftboosterParticles.Play();
    }
    private void StopRotate()
    {
        rb.angularVelocity = Vector3.Lerp(rb.angularVelocity, Vector3.zero, rotationDamping * Time.fixedDeltaTime);
        LeftboosterParticles.Stop();
        RightboosterParticles.Stop();
    }
}
